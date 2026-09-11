///|
pub fn canonical_credential_name(provider_name : String) -> String {
  provider_name.trim().to_owned().to_lower()
}

///|
pub fn provider_api_key_env_var(provider_name : String) -> String {
  let canonical = canonical_credential_name(provider_name)
  let buffer = StringBuilder(size_hint=canonical.length() + 16)
  buffer.write_string("ASWITCH_")
  for char in canonical {
    if char.is_ascii_alphabetic() || char.is_ascii_digit() {
      buffer.write_string(char.to_string().to_upper())
    } else {
      buffer.write_char('_')
    }
  }
  buffer.write_string("_API_KEY")
  buffer.to_string()
}
