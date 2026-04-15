///|
/// Configuration validation module

///|
/// Validation error type
pub enum ValidationError {
  /// Provider has empty name
  EmptyProviderName
  /// Provider has empty API key
  EmptyApiKey
  /// Provider has no API base URLs configured
  NoBaseUrls
  /// Provider has invalid base URL format
  InvalidBaseUrl(String)
  /// Provider has no models configured
  NoModels
  /// Duplicate provider name found in config
  DuplicateProviderName(String)
  /// Model has empty name
  EmptyModelName
  /// Model has invalid context window size
  InvalidContextWindow(Int)
} derive(Debug, Eq)

///|
/// Validate a single Provider configuration
pub fn validate_provider(
  provider : @provider.Provider,
) -> Result[Unit, ValidationError] {
  // To implement
  Ok(())
}

///|
/// Validate entire Config structure
pub fn validate_config(config : Config) -> Result[Unit, ValidationError] {
  // To implement
  Ok(())
}
