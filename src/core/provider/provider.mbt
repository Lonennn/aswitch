///|
/// Provider configuration for AI model providers
pub(all) struct Provider {
  /// provider name/alias for display
  name : String
  /// Optional legacy inline API key for the provider
  api_key : String?
  /// OpenAI-compatible API base URL (e.g., https://api.openai.com/v1)
  openai_base_url : String?
  /// Anthropic-compatible API base URL (e.g., https://api.anthropic.com)
  anthropic_base_url : String?
  /// Models to use
  models : Array[Model]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub suberror ProviderLackApiKeyError {
  ProviderLackApiKeyError(String)
}

///|
pub fn Provider::deep_copy(self : Provider) -> Provider {
  let api_key = match self.api_key {
    Some(key) => Some(key.to_string())
    None => None
  }
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
    api_key,
    openai_base_url,
    anthropic_base_url,
    models,
  }
}

///|
pub fn Provider::with_api_key(self : Provider, api_key : String) -> Provider {
  Provider::{
    name: self.name.to_string(),
    api_key: Some(api_key),
    openai_base_url: match self.openai_base_url {
      Some(url) => Some(url.to_string())
      None => None
    },
    anthropic_base_url: match self.anthropic_base_url {
      Some(url) => Some(url.to_string())
      None => None
    },
    models: self.models.map(fn(model) { model.deep_copy() }),
  }
}

///|
pub fn Provider::without_api_key(self : Provider) -> Provider {
  Provider::{
    name: self.name.to_string(),
    api_key: None,
    openai_base_url: match self.openai_base_url {
      Some(url) => Some(url.to_string())
      None => None
    },
    anthropic_base_url: match self.anthropic_base_url {
      Some(url) => Some(url.to_string())
      None => None
    },
    models: self.models.map(fn(model) { model.deep_copy() }),
  }
}

///|
pub fn Provider::require_api_key(self : Provider) -> String raise Error {
  match self.api_key {
    Some(api_key) =>
      if api_key.trim().is_empty() {
        raise ProviderLackApiKeyError(
          "resolved API key is required for provider '\{self.name}'",
        )
      } else {
        api_key
      }
    None =>
      raise ProviderLackApiKeyError(
        "resolved API key is required for provider '\{self.name}'",
      )
  }
}

///|
/// Modality enum for model input/output capabilities
pub(all) enum Modality {
  Text
  Vision
  Audio
} derive(Debug, Eq, ToJson, FromJson)
