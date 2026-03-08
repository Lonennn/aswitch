///|
/// Provider configuration for AI model providers
pub(all) struct Provider {
  /// provider name/alias for display
  name : String
  /// API key for the provider
  api_key : String
  /// OpenAI-compatible API base URL (e.g., https://api.openai.com/v1)
  openai_base_url : String?
  /// Anthropic-compatible API base URL (e.g., https://api.anthropic.com)
  anthropic_base_url : String?
  /// Model name to use
  models : Array[String]
} derive(Show, Eq, ToJson, FromJson)
