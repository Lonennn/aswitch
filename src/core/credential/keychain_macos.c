#if defined(__APPLE__)

#include "keychain.h"

#include <dlfcn.h>
#include <stddef.h>
#include <stdint.h>

typedef int32_t OSStatus;
typedef long CFIndex;
typedef uint32_t CFStringEncoding;
typedef uint8_t Boolean;
typedef const void *CFAllocatorRef;
typedef const void *CFTypeRef;
typedef const void *CFStringRef;
typedef const void *CFDataRef;
typedef const void *CFDictionaryRef;
typedef void *CFMutableDictionaryRef;
typedef const void *SecKeychainRef;

typedef CFStringRef (*CFStringCreateWithBytesFn)(
    CFAllocatorRef allocator, const uint8_t *bytes, CFIndex length,
    CFStringEncoding encoding, Boolean is_external_representation);
typedef CFDataRef (*CFDataCreateFn)(CFAllocatorRef allocator,
                                   const uint8_t *bytes, CFIndex length);
typedef CFIndex (*CFDataGetLengthFn)(CFDataRef data);
typedef const uint8_t *(*CFDataGetBytePtrFn)(CFDataRef data);
typedef CFMutableDictionaryRef (*CFDictionaryCreateMutableFn)(
    CFAllocatorRef allocator, CFIndex capacity, const void *key_callbacks,
    const void *value_callbacks);
typedef void (*CFDictionarySetValueFn)(CFMutableDictionaryRef dictionary,
                                      const void *key, const void *value);
typedef void (*CFReleaseFn)(CFTypeRef value);

typedef OSStatus (*SecItemCopyMatchingFn)(CFDictionaryRef query,
                                         CFTypeRef *result);
typedef OSStatus (*SecItemAddFn)(CFDictionaryRef attributes, CFTypeRef *result);
typedef OSStatus (*SecItemUpdateFn)(CFDictionaryRef query,
                                   CFDictionaryRef attributes);
typedef OSStatus (*SecItemDeleteFn)(CFDictionaryRef query);
typedef OSStatus (*SecKeychainGetUserInteractionAllowedFn)(Boolean *state);
typedef OSStatus (*SecKeychainSetUserInteractionAllowedFn)(Boolean state);
typedef OSStatus (*SecKeychainCopyDefaultFn)(SecKeychainRef *keychain);
typedef OSStatus (*SecKeychainGetStatusFn)(SecKeychainRef keychain,
                                          uint32_t *status);

enum {
  ASWITCH_ERR_SEC_SUCCESS = 0,
  ASWITCH_ERR_SEC_USER_CANCELED = -128,
  ASWITCH_ERR_SEC_AUTH_FAILED = -25293,
  ASWITCH_ERR_SEC_NO_SUCH_KEYCHAIN = -25294,
  ASWITCH_ERR_SEC_NOT_AVAILABLE = -25291,
  ASWITCH_ERR_SEC_INTERACTION_NOT_ALLOWED = -25308,
  ASWITCH_ERR_SEC_INTERACTION_REQUIRED = -25320,
  ASWITCH_ERR_SEC_ITEM_NOT_FOUND = -25300,
  ASWITCH_ERR_SEC_NO_DEFAULT_KEYCHAIN = -25307,
};

enum { ASWITCH_CF_STRING_ENCODING_UTF8 = 0x08000100 };
enum { ASWITCH_SEC_UNLOCK_STATE_STATUS = 1 };

static void *security_handle = NULL;
static void *core_foundation_handle = NULL;
static int keychain_symbols_loaded = 0;

static CFStringCreateWithBytesFn p_cf_string_create_with_bytes = NULL;
static CFDataCreateFn p_cf_data_create = NULL;
static CFDataGetLengthFn p_cf_data_get_length = NULL;
static CFDataGetBytePtrFn p_cf_data_get_byte_ptr = NULL;
static CFDictionaryCreateMutableFn p_cf_dictionary_create_mutable = NULL;
static CFDictionarySetValueFn p_cf_dictionary_set_value = NULL;
static CFReleaseFn p_cf_release = NULL;
static SecItemCopyMatchingFn p_sec_item_copy_matching = NULL;
static SecItemAddFn p_sec_item_add = NULL;
static SecItemUpdateFn p_sec_item_update = NULL;
static SecItemDeleteFn p_sec_item_delete = NULL;
static SecKeychainGetUserInteractionAllowedFn
    p_sec_keychain_get_user_interaction_allowed = NULL;
static SecKeychainSetUserInteractionAllowedFn
    p_sec_keychain_set_user_interaction_allowed = NULL;
static SecKeychainCopyDefaultFn p_sec_keychain_copy_default = NULL;
static SecKeychainGetStatusFn p_sec_keychain_get_status = NULL;

static const void *p_cf_type_dictionary_key_callbacks = NULL;
static const void *p_cf_type_dictionary_value_callbacks = NULL;
static CFTypeRef cf_boolean_true = NULL;
static CFTypeRef sec_class = NULL;
static CFTypeRef sec_class_generic_password = NULL;
static CFTypeRef sec_attr_service = NULL;
static CFTypeRef sec_attr_account = NULL;
static CFTypeRef sec_value_data = NULL;
static CFTypeRef sec_return_data = NULL;

static CFTypeRef load_cf_constant(void *handle, const char *name) {
  CFTypeRef *constant = (CFTypeRef *)dlsym(handle, name);
  return constant == NULL ? NULL : *constant;
}

static int load_keychain_symbols(void) {
  if (keychain_symbols_loaded) {
    return 1;
  }

  security_handle = dlopen(
      "/System/Library/Frameworks/Security.framework/Security",
      RTLD_LAZY | RTLD_LOCAL);
  core_foundation_handle = dlopen(
      "/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation",
      RTLD_LAZY | RTLD_LOCAL);
  if (security_handle == NULL || core_foundation_handle == NULL) {
    return 0;
  }

  p_cf_string_create_with_bytes = (CFStringCreateWithBytesFn)dlsym(
      core_foundation_handle, "CFStringCreateWithBytes");
  p_cf_data_create =
      (CFDataCreateFn)dlsym(core_foundation_handle, "CFDataCreate");
  p_cf_data_get_length =
      (CFDataGetLengthFn)dlsym(core_foundation_handle, "CFDataGetLength");
  p_cf_data_get_byte_ptr =
      (CFDataGetBytePtrFn)dlsym(core_foundation_handle, "CFDataGetBytePtr");
  p_cf_dictionary_create_mutable = (CFDictionaryCreateMutableFn)dlsym(
      core_foundation_handle, "CFDictionaryCreateMutable");
  p_cf_dictionary_set_value = (CFDictionarySetValueFn)dlsym(
      core_foundation_handle, "CFDictionarySetValue");
  p_cf_release = (CFReleaseFn)dlsym(core_foundation_handle, "CFRelease");
  p_cf_type_dictionary_key_callbacks =
      dlsym(core_foundation_handle, "kCFTypeDictionaryKeyCallBacks");
  p_cf_type_dictionary_value_callbacks =
      dlsym(core_foundation_handle, "kCFTypeDictionaryValueCallBacks");
  cf_boolean_true =
      load_cf_constant(core_foundation_handle, "kCFBooleanTrue");

  p_sec_item_copy_matching = (SecItemCopyMatchingFn)dlsym(
      security_handle, "SecItemCopyMatching");
  p_sec_item_add =
      (SecItemAddFn)dlsym(security_handle, "SecItemAdd");
  p_sec_item_update =
      (SecItemUpdateFn)dlsym(security_handle, "SecItemUpdate");
  p_sec_item_delete =
      (SecItemDeleteFn)dlsym(security_handle, "SecItemDelete");
  p_sec_keychain_get_user_interaction_allowed =
      (SecKeychainGetUserInteractionAllowedFn)dlsym(
          security_handle, "SecKeychainGetUserInteractionAllowed");
  p_sec_keychain_set_user_interaction_allowed =
      (SecKeychainSetUserInteractionAllowedFn)dlsym(
          security_handle, "SecKeychainSetUserInteractionAllowed");
  p_sec_keychain_copy_default = (SecKeychainCopyDefaultFn)dlsym(
      security_handle, "SecKeychainCopyDefault");
  p_sec_keychain_get_status = (SecKeychainGetStatusFn)dlsym(
      security_handle, "SecKeychainGetStatus");
  sec_class = load_cf_constant(security_handle, "kSecClass");
  sec_class_generic_password =
      load_cf_constant(security_handle, "kSecClassGenericPassword");
  sec_attr_service = load_cf_constant(security_handle, "kSecAttrService");
  sec_attr_account = load_cf_constant(security_handle, "kSecAttrAccount");
  sec_value_data = load_cf_constant(security_handle, "kSecValueData");
  sec_return_data = load_cf_constant(security_handle, "kSecReturnData");

  keychain_symbols_loaded =
      p_cf_string_create_with_bytes != NULL && p_cf_data_create != NULL &&
      p_cf_data_get_length != NULL && p_cf_data_get_byte_ptr != NULL &&
      p_cf_dictionary_create_mutable != NULL &&
      p_cf_dictionary_set_value != NULL && p_cf_release != NULL &&
      p_cf_type_dictionary_key_callbacks != NULL &&
      p_cf_type_dictionary_value_callbacks != NULL &&
      cf_boolean_true != NULL && p_sec_item_copy_matching != NULL &&
      p_sec_item_add != NULL && p_sec_item_update != NULL &&
      p_sec_item_delete != NULL &&
      p_sec_keychain_get_user_interaction_allowed != NULL &&
      p_sec_keychain_set_user_interaction_allowed != NULL &&
      p_sec_keychain_copy_default != NULL &&
      p_sec_keychain_get_status != NULL &&
      sec_class != NULL && sec_class_generic_password != NULL &&
      sec_attr_service != NULL && sec_attr_account != NULL &&
      sec_value_data != NULL && sec_return_data != NULL;
  return keychain_symbols_loaded;
}

static int map_osstatus(OSStatus status) {
  switch (status) {
  case ASWITCH_ERR_SEC_SUCCESS:
    return ASWITCH_KEYCHAIN_RESOLVED;
  case ASWITCH_ERR_SEC_ITEM_NOT_FOUND:
    return ASWITCH_KEYCHAIN_MISSING;
  case ASWITCH_ERR_SEC_NO_DEFAULT_KEYCHAIN:
  case ASWITCH_ERR_SEC_NOT_AVAILABLE:
    return ASWITCH_KEYCHAIN_UNAVAILABLE;
  case ASWITCH_ERR_SEC_INTERACTION_NOT_ALLOWED:
  case ASWITCH_ERR_SEC_INTERACTION_REQUIRED:
    return ASWITCH_KEYCHAIN_LOCKED;
  case ASWITCH_ERR_SEC_USER_CANCELED:
  case ASWITCH_ERR_SEC_AUTH_FAILED:
  case ASWITCH_ERR_SEC_NO_SUCH_KEYCHAIN:
  default:
    return ASWITCH_KEYCHAIN_DENIED;
  }
}

static CFStringRef create_cf_string(const uint8_t *bytes, CFIndex length) {
  return p_cf_string_create_with_bytes(
      NULL, bytes, length, ASWITCH_CF_STRING_ENCODING_UTF8, 0);
}

static CFMutableDictionaryRef create_dictionary(CFIndex capacity) {
  return p_cf_dictionary_create_mutable(
      NULL, capacity, p_cf_type_dictionary_key_callbacks,
      p_cf_type_dictionary_value_callbacks);
}

static void add_query_values(CFMutableDictionaryRef query, CFStringRef service,
                             CFStringRef account) {
  p_cf_dictionary_set_value(query, sec_class, sec_class_generic_password);
  p_cf_dictionary_set_value(query, sec_attr_service, service);
  p_cf_dictionary_set_value(query, sec_attr_account, account);
}

static int create_query(moonbit_bytes_t account, CFStringRef *service_out,
                        CFStringRef *account_out,
                        CFMutableDictionaryRef *query_out) {
  *service_out = create_cf_string(
      (const uint8_t *)ASWITCH_KEYCHAIN_SERVICE,
      (CFIndex)(sizeof(ASWITCH_KEYCHAIN_SERVICE) - 1));
  *account_out = create_cf_string(
      (const uint8_t *)account, (CFIndex)Moonbit_array_length(account));
  if (*service_out == NULL || *account_out == NULL) {
    goto failure;
  }

  *query_out = create_dictionary(3);
  if (*query_out == NULL) {
    goto failure;
  }
  add_query_values(*query_out, *service_out, *account_out);
  return 1;

failure:
  if (*service_out != NULL) {
    p_cf_release(*service_out);
    *service_out = NULL;
  }
  if (*account_out != NULL) {
    p_cf_release(*account_out);
    *account_out = NULL;
  }
  return 0;
}

static void release_query(CFStringRef service, CFStringRef account,
                          CFMutableDictionaryRef query) {
  if (query != NULL) {
    p_cf_release(query);
  }
  if (account != NULL) {
    p_cf_release(account);
  }
  if (service != NULL) {
    p_cf_release(service);
  }
}

static OSStatus disable_user_interaction(Boolean *previous_state) {
  OSStatus status =
      p_sec_keychain_get_user_interaction_allowed(previous_state);
  if (status != ASWITCH_ERR_SEC_SUCCESS) {
    return status;
  }
  return p_sec_keychain_set_user_interaction_allowed(0);
}

static void restore_user_interaction(Boolean previous_state) {
  (void)p_sec_keychain_set_user_interaction_allowed(previous_state);
}

static OSStatus check_default_keychain_unlocked(void) {
  SecKeychainRef keychain = NULL;
  OSStatus status = p_sec_keychain_copy_default(&keychain);
  if (status != ASWITCH_ERR_SEC_SUCCESS) {
    return status;
  }

  uint32_t keychain_status = 0;
  status = p_sec_keychain_get_status(keychain, &keychain_status);
  p_cf_release(keychain);
  if (status != ASWITCH_ERR_SEC_SUCCESS) {
    return status;
  }
  return (keychain_status & ASWITCH_SEC_UNLOCK_STATE_STATUS) != 0
             ? ASWITCH_ERR_SEC_SUCCESS
             : ASWITCH_ERR_SEC_INTERACTION_NOT_ALLOWED;
}

MOONBIT_FFI_EXPORT
moonbit_bytes_t aswitch_keychain_read(moonbit_bytes_t account) {
  if (!load_keychain_symbols()) {
    return aswitch_keychain_read_result(ASWITCH_KEYCHAIN_UNAVAILABLE, NULL, 0);
  }

  Boolean previous_interaction_state = 1;
  OSStatus interaction_status =
      disable_user_interaction(&previous_interaction_state);
  if (interaction_status != ASWITCH_ERR_SEC_SUCCESS) {
    return aswitch_keychain_read_result(map_osstatus(interaction_status), NULL,
                                        0);
  }

  CFStringRef service = NULL;
  CFStringRef account_string = NULL;
  CFMutableDictionaryRef query = NULL;
  if (!create_query(account, &service, &account_string, &query)) {
    restore_user_interaction(previous_interaction_state);
    return aswitch_keychain_read_result(ASWITCH_KEYCHAIN_CORRUPT, NULL, 0);
  }
  p_cf_dictionary_set_value(query, sec_return_data, cf_boolean_true);

  CFTypeRef data = NULL;
  OSStatus status = p_sec_item_copy_matching(query, &data);
  release_query(service, account_string, query);
  restore_user_interaction(previous_interaction_state);
  if (status != ASWITCH_ERR_SEC_SUCCESS) {
    return aswitch_keychain_read_result(map_osstatus(status), NULL, 0);
  }
  if (data == NULL) {
    return aswitch_keychain_read_result(ASWITCH_KEYCHAIN_CORRUPT, NULL, 0);
  }

  CFIndex length = p_cf_data_get_length((CFDataRef)data);
  const uint8_t *bytes = p_cf_data_get_byte_ptr((CFDataRef)data);
  moonbit_bytes_t result;
  if (length < 0 || (length > 0 && bytes == NULL) || length > UINT32_MAX) {
    result =
        aswitch_keychain_read_result(ASWITCH_KEYCHAIN_CORRUPT, NULL, 0);
  } else {
    result = aswitch_keychain_read_result(ASWITCH_KEYCHAIN_RESOLVED, bytes,
                                          (uint32_t)length);
  }
  p_cf_release(data);
  return result;
}

MOONBIT_FFI_EXPORT
int aswitch_keychain_write(moonbit_bytes_t account, moonbit_bytes_t secret) {
  if (!load_keychain_symbols()) {
    return ASWITCH_KEYCHAIN_UNAVAILABLE;
  }

  Boolean previous_interaction_state = 1;
  OSStatus interaction_status =
      disable_user_interaction(&previous_interaction_state);
  if (interaction_status != ASWITCH_ERR_SEC_SUCCESS) {
    return map_osstatus(interaction_status);
  }

  CFStringRef service = NULL;
  CFStringRef account_string = NULL;
  CFMutableDictionaryRef query = NULL;
  if (!create_query(account, &service, &account_string, &query)) {
    restore_user_interaction(previous_interaction_state);
    return ASWITCH_KEYCHAIN_CORRUPT;
  }

  CFDataRef data = p_cf_data_create(
      NULL, (const uint8_t *)secret, (CFIndex)Moonbit_array_length(secret));
  CFMutableDictionaryRef updates = create_dictionary(1);
  if (data == NULL || updates == NULL) {
    if (updates != NULL) {
      p_cf_release(updates);
    }
    if (data != NULL) {
      p_cf_release(data);
    }
    release_query(service, account_string, query);
    restore_user_interaction(previous_interaction_state);
    return ASWITCH_KEYCHAIN_CORRUPT;
  }
  p_cf_dictionary_set_value(updates, sec_value_data, data);

  Boolean interaction_disabled = 1;
  OSStatus status = p_sec_item_update(query, updates);
  p_cf_release(updates);
  if (status == ASWITCH_ERR_SEC_ITEM_NOT_FOUND) {
    status = check_default_keychain_unlocked();
    if (status == ASWITCH_ERR_SEC_SUCCESS) {
      restore_user_interaction(previous_interaction_state);
      interaction_disabled = 0;
      p_cf_dictionary_set_value(query, sec_value_data, data);
      status = p_sec_item_add(query, NULL);
    }
  }

  p_cf_release(data);
  release_query(service, account_string, query);
  if (interaction_disabled) {
    restore_user_interaction(previous_interaction_state);
  }
  return map_osstatus(status);
}

MOONBIT_FFI_EXPORT
int aswitch_keychain_delete(moonbit_bytes_t account) {
  if (!load_keychain_symbols()) {
    return ASWITCH_KEYCHAIN_UNAVAILABLE;
  }

  Boolean previous_interaction_state = 1;
  OSStatus interaction_status =
      disable_user_interaction(&previous_interaction_state);
  if (interaction_status != ASWITCH_ERR_SEC_SUCCESS) {
    return map_osstatus(interaction_status);
  }

  CFStringRef service = NULL;
  CFStringRef account_string = NULL;
  CFMutableDictionaryRef query = NULL;
  if (!create_query(account, &service, &account_string, &query)) {
    restore_user_interaction(previous_interaction_state);
    return ASWITCH_KEYCHAIN_CORRUPT;
  }

  OSStatus status = p_sec_item_delete(query);
  release_query(service, account_string, query);
  restore_user_interaction(previous_interaction_state);
  return map_osstatus(status);
}

#endif
