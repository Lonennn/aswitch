///|
pub enum CredentialSource {
  EnvironmentVariable(String)
  OSKeychain
  LegacyInline
} derive(Debug, Eq)

///|
pub extend CredentialSource with Debug::{to_repr}

///|
pub extend CredentialSource with Eq::{not_equal, equal}

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
pub extend CredentialBackendStatus with Debug::{to_repr}

///|
pub extend CredentialBackendStatus with Eq::{not_equal, equal}

///|
pub struct ResolvedCredential {
  value : String
  source : CredentialSource
} derive(Debug, Eq)

///|
pub extend ResolvedCredential with Debug::{to_repr}

///|
pub extend ResolvedCredential with Eq::{not_equal, equal}

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
