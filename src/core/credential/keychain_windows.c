#if defined(_WIN32)

#include "keychain.h"

MOONBIT_FFI_EXPORT
moonbit_bytes_t aswitch_keychain_read(moonbit_bytes_t account) {
  (void)account;
  return aswitch_keychain_read_result(ASWITCH_KEYCHAIN_UNAVAILABLE, NULL, 0);
}

MOONBIT_FFI_EXPORT
int aswitch_keychain_write(moonbit_bytes_t account, moonbit_bytes_t secret) {
  (void)account;
  (void)secret;
  return ASWITCH_KEYCHAIN_UNAVAILABLE;
}

MOONBIT_FFI_EXPORT
int aswitch_keychain_delete(moonbit_bytes_t account) {
  (void)account;
  return ASWITCH_KEYCHAIN_UNAVAILABLE;
}

#endif
