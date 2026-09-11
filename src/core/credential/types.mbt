///|
pub enum CredentialSource {
  EnvironmentVariable(String)
  OSKeychain
  LegacyInline
} derive(Debug, Eq)

///|
pub enum CredentialBackendStatus {
  Resolved
  Missing
  Unavailable
  Locked
  Denied
  Corrupt
} derive(Debug, Eq)

///|
pub struct ResolvedCredential {
  value : String
  source : CredentialSource
} derive(Debug, Eq)

///|
pub fn credential_backend_status_message(
  state : CredentialBackendStatus,
) -> String {
  match state {
    Resolved => "resolved"
    Missing => "missing"
    Unavailable => "unavailable"
    Locked => "locked"
    Denied => "denied"
    Corrupt => "corrupt"
  }
}
