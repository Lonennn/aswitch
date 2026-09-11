///|
pub fn resolve_provider_credential(
  provider : @provider.Provider,
) -> Result[ResolvedCredential, String] {
  let env_var = provider_api_key_env_var(provider.name)
  match @env.get_env_var(env_var) {
    Some(value) =>
      if !value.trim().is_empty() {
        return Ok(ResolvedCredential::{
          value,
          source: EnvironmentVariable(env_var),
        })
      }
    None => ()
  }

  match read_os_keychain_secret(provider.name) {
    Ok(Some(credential)) => return Ok(credential)
    Ok(None) | Err(Unavailable) => ()
    Err(state) =>
      return Err(
        "Credential lookup for provider '\{provider.name}' stopped because the OS keychain is \{credential_backend_status_message(state)}",
      )
  }

  match provider.api_key {
    Some(key) =>
      if !key.trim().is_empty() {
        Ok(ResolvedCredential::{ value: key, source: LegacyInline, })
      } else {
        Err("Provider '\{provider.name}' has no resolvable API key")
      }
    None => Err("Provider '\{provider.name}' has no resolvable API key")
  }
}

///|
pub fn provider_with_resolved_credential(
  provider : @provider.Provider,
) -> Result[@provider.Provider, String] {
  match resolve_provider_credential(provider) {
    Ok(credential) => Ok(provider.with_api_key(credential.value))
    Err(err) => Err(err)
  }
}
