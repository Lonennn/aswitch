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
  /// Models to use
  models : Array[Model]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn Provider::deep_copy(self : Provider) -> Provider {
  let openai_base_url = match self.openai_base_url {
    Some(url) => Some(url.to_string())
    None => None
  }
  let anthropic_base_url = match self.anthropic_base_url {
    Some(url) => Some(url.to_string())
    None => None
  }
  let models = self.models.map(fn(model) { model.deep_copy() })
  Provider::{
    name: self.name.to_string(),
    api_key: self.api_key.to_string(),
    openai_base_url,
    anthropic_base_url,
    models,
  }
}

///|
/// Modality enum for model input/output capabilities
pub(all) enum Modality {
  Text
  Vision
  Audio
} derive(Debug, Eq, ToJson, FromJson)
