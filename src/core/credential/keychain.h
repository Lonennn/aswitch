#ifndef ASWITCH_KEYCHAIN_H
#define ASWITCH_KEYCHAIN_H

#include <moonbit.h>
#include <limits.h>
#include <stdint.h>
#include <string.h>

enum {
  ASWITCH_KEYCHAIN_RESOLVED = 0,
  ASWITCH_KEYCHAIN_MISSING = 1,
  ASWITCH_KEYCHAIN_UNAVAILABLE = 2,
  ASWITCH_KEYCHAIN_LOCKED = 3,
  ASWITCH_KEYCHAIN_DENIED = 4,
  ASWITCH_KEYCHAIN_CORRUPT = 5,
};

#define ASWITCH_KEYCHAIN_SERVICE "aswitch"

static inline moonbit_bytes_t aswitch_keychain_read_result(
    int status, const void *secret, uint32_t secret_len) {
  if (status == ASWITCH_KEYCHAIN_RESOLVED &&
      ((secret == NULL && secret_len > 0) || secret_len > INT32_MAX - 1)) {
    status = ASWITCH_KEYCHAIN_CORRUPT;
  }
  if (status != ASWITCH_KEYCHAIN_RESOLVED) {
    secret = NULL;
    secret_len = 0;
  }

  moonbit_bytes_t result = moonbit_make_bytes_raw((int32_t)secret_len + 1);
  result[0] = (uint8_t)status;
  if (secret_len > 0) {
    memcpy(result + 1, secret, secret_len);
  }
  return result;
}

#endif
