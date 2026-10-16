///|
pub const KEYCHAIN_SERVICE : String = "aswitch"

///|
pub const DISABLE_KEYCHAIN_ENV : String = "ASWITCH_DISABLE_KEYCHAIN"

///|
fn is_keychain_disabled() -> Bool {
  match @env.get_env_var(DISABLE_KEYCHAIN_ENV) {
    Some(value) => {
      let normalized = value.trim().to_lower()
      normalized == "1" || normalized == "true" || normalized == "yes"
    }
    None => false
  }
}

///|
#cfg(any(target="native", target="llvm"))
#borrow(account)
extern "c" fn keychain_read_ffi(account : Bytes) -> Bytes = "aswitch_keychain_read"

///|
#cfg(any(target="native", target="llvm"))
#borrow(account, secret)
extern "c" fn keychain_write_ffi(account : Bytes, secret : Bytes) -> Int32 = "aswitch_keychain_write"

///|
#cfg(any(target="native", target="llvm"))
#borrow(account)
extern "c" fn keychain_delete_ffi(account : Bytes) -> Int32 = "aswitch_keychain_delete"

///|
#cfg(not(any(target="native", target="llvm")))
fn keychain_read_ffi(_account : Bytes) -> Bytes {
  [2] // Unavailable
}

///|
#cfg(not(any(target="native", target="llvm")))
fn keychain_write_ffi(_account : Bytes, _secret : Bytes) -> Int32 {
  2 // Unavailable
}

///|
#cfg(not(any(target="native", target="llvm")))
fn keychain_delete_ffi(_account : Bytes) -> Int32 {
  2 // Unavailable
}

///|
fn keychain_status_from_code(code : Int32) -> CredentialBackendStatus {
  match code {
    0 => Resolved
    1 => Missing
    2 => Unavailable
    3 => Locked
    4 => Denied
    5 => Corrupt
    _ => Corrupt
  }
}

///|
fn decode_keychain_read_result(
  result : Bytes,
) -> Result[String?, CredentialBackendStatus] {
  if result.length() == 0 {
    return Err(Corrupt)
  }
  match keychain_status_from_code(result[0].to_int()) {
    Resolved =>
      try @utf8.decode(result[1:]) catch {
        _ => Err(Corrupt)
      } noraise {
        secret =>
          if secret.trim().is_empty() {
            Err(Corrupt)
          } else {
            Ok(Some(secret))
          }
      }
    Missing => Ok(None)
    Unavailable => Err(Unavailable)
    Locked => Err(Locked)
    Denied => Err(Denied)
    Corrupt => Err(Corrupt)
  }
}

///|
pub fn read_os_keychain_secret(
  provider_name : String,
) -> Result[ResolvedCredential?, CredentialBackendStatus] {
  if is_keychain_disabled() {
    return Err(Unavailable)
  }
  let account = @utf8.encode(canonical_credential_name(provider_name))
  match decode_keychain_read_result(keychain_read_ffi(account)) {
    Ok(Some(secret)) => Ok(Some({ value: secret, source: OSKeychain, }))
    Ok(None) => Ok(None)
    Err(err) => Err(err)
  }
}

///|
pub fn write_os_keychain_secret(
  provider_name : String,
  secret : String,
) -> Result[Unit, CredentialBackendStatus] {
  if is_keychain_disabled() {
    return Err(Unavailable)
  }
  if secret.trim().is_empty() {
    return Err(Corrupt)
  }
  let account = @utf8.encode(canonical_credential_name(provider_name))
  let secret_bytes = @utf8.encode(secret)
  let status = keychain_status_from_code(
    keychain_write_ffi(account, secret_bytes),
  )
  match status {
    Resolved => Ok(())
    Missing => Err(Missing)
    Unavailable => Err(Unavailable)
    Locked => Err(Locked)
    Denied => Err(Denied)
    Corrupt => Err(Corrupt)
  }
}

///|
pub fn delete_os_keychain_secret(
  provider_name : String,
) -> Result[Unit, CredentialBackendStatus] {
  if is_keychain_disabled() {
    return Err(Unavailable)
  }
  let account = @utf8.encode(canonical_credential_name(provider_name))
  let status = keychain_status_from_code(keychain_delete_ffi(account))
  match status {
    Resolved | Missing => Ok(())
    Unavailable => Err(Unavailable)
    Locked => Err(Locked)
    Denied => Err(Denied)
    Corrupt => Err(Corrupt)
  }
}
