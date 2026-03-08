///|
/// Provider configuration for AI model providers
pub(all) struct Provider {
  /// provider name/alias for display
  name : String
  /// API key for the provider
  api_key : String
  /// Base URL for the API endpoint
  base_url : String
  /// Model name to use
  models : Array[String]
} derive(Show, Eq, ToJson, FromJson)
