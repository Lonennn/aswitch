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
