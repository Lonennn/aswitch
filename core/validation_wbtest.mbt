///|
test "validate provider with empty name returns error" {
  let provider = @provider.Provider::{
    name: "",
    api_key: "sk-xxx",
    openai_base_url: Some("https://api.openai.com/v1"),
    anthropic_base_url: None,
    models: [],
  }
  let result = validate_provider(provider)
  assert_true(result is Err(ValidationError::EmptyProviderName))
}

///|
test "validate valid provider returns ok" {
  let provider = @provider.Provider::{
    name: "openai",
    api_key: "sk-xxx",
    openai_base_url: Some("https://api.openai.com/v1"),
    anthropic_base_url: None,
    models: [@provider.Model::new(name="gpt-4o", context_limit=128000)],
  }
  let result = validate_provider(provider)
  assert_true(result is Ok(_))
}

///|
test "validate provider with empty api key returns error" {
  let provider = @provider.Provider::{
    name: "openai",
    api_key: "",
    openai_base_url: Some("https://api.openai.com/v1"),
    anthropic_base_url: None,
    models: [],
  }
  let result = validate_provider(provider)
  assert_true(result is Err(ValidationError::EmptyApiKey))
}

///|
test "validate provider with invalid url returns error" {
  let provider = @provider.Provider::{
    name: "openai",
    api_key: "sk-xxx",
    openai_base_url: Some("api.openai.com/v1"), // Missing https://
    anthropic_base_url: None,
    models: [],
  }
  let result = validate_provider(provider)
  assert_true(result is Err(ValidationError::InvalidBaseUrl(_)))
}

///|
test "validate config with duplicate provider names returns error" {
  let provider1 = @provider.Provider::{
    name: "openai",
    api_key: "sk-xxx",
    openai_base_url: Some("https://api.openai.com/v1"),
    anthropic_base_url: None,
    models: [@provider.Model::new(name="gpt-4o", context_limit=128000)],
  }

  let provider2 = @provider.Provider::{
    name: "OpenAI", // Duplicate case-insensitive
    api_key: "sk-yyy",
    anthropic_base_url: Some("https://api.anthropic.com"),
    openai_base_url: None,
    models: [@provider.Model::new(name="claude-3-opus", context_limit=200000)],
  }

  let config = Config::{ providers: @list.from_array([provider1, provider2]) }
  let result = validate_config(config)
  assert_true(result is Err(ValidationError::DuplicateProviderName(_)))
}

///|
test "validate valid config returns ok" {
  let provider = @provider.Provider::{
    name: "openai",
    api_key: "sk-xxx",
    openai_base_url: Some("https://api.openai.com/v1"),
    anthropic_base_url: None,
    models: [@provider.Model::new(name="gpt-4o", context_limit=128000)],
  }
  let config = Config::{ providers: @list.from_array([provider]) }
  let result = validate_config(config)
  assert_true(result is Ok(_))
}
