///|
test "resolve_provider exact match" {
  let config = Config::new()
  let provider = @provider.Provider::{
    name: "openai",
    api_key: "key",
    openai_base_url: Some("https://api.openai.com/v1"),
    anthropic_base_url: None,
    models: [@provider.Model::new(name="gpt-4")],
  }
  config.providers = @list.from_array([provider])
  assert_true(config.resolve_provider("openai") is Ok(p) && p.name == "openai")
}

///|
test "resolve_provider prefix match" {
  let config = Config::new()
  let provider = @provider.Provider::{
    name: "openai",
    api_key: "key",
    openai_base_url: Some("https://api.openai.com/v1"),
    anthropic_base_url: None,
    models: [@provider.Model::new(name="gpt-4")],
  }
  config.providers = @list.from_array([provider])
  assert_true(config.resolve_provider("ope") is Ok(p) && p.name == "openai")
}

///|
test "resolve_provider case-insensitive exact match" {
  let config = Config::new()
  let provider = @provider.Provider::{
    name: "OpenAI",
    api_key: "key",
    openai_base_url: Some("https://api.openai.com/v1"),
    anthropic_base_url: None,
    models: [@provider.Model::new(name="gpt-4")],
  }
  config.providers = @list.from_array([provider])
  assert_true(config.resolve_provider("openai") is Ok(p) && p.name == "OpenAI")
}

///|
test "resolve_provider ambiguous prefix" {
  let config = Config::new()
  let p1 = @provider.Provider::{
    name: "openai",
    api_key: "key1",
    openai_base_url: Some("https://api.openai.com/v1"),
    anthropic_base_url: None,
    models: [@provider.Model::new(name="gpt-4")],
  }
  let p2 = @provider.Provider::{
    name: "openrouter",
    api_key: "key2",
    openai_base_url: Some("https://openrouter.ai/api/v1"),
    anthropic_base_url: None,
    models: [@provider.Model::new(name="llama")],
  }
  config.providers = @list.from_array([p1, p2])
  assert_true(config.resolve_provider("open") is Err(_))
}

///|
test "resolve_provider too short prefix" {
  let config = Config::new()
  let provider = @provider.Provider::{
    name: "openai",
    api_key: "key",
    openai_base_url: Some("https://api.openai.com/v1"),
    anthropic_base_url: None,
    models: [@provider.Model::new(name="gpt-4")],
  }
  config.providers = @list.from_array([provider])
  assert_true(config.resolve_provider("o") is Err(_))
}

///|
test "resolve_provider unknown" {
  let config = Config::new()
  assert_true(config.resolve_provider("unknown") is Err(_))
}
