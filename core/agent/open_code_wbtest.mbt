///|
/// Whitebox tests for OpenCode agent - testing private functions

///|
/// Sample OpenCode configuration with sensitive information replaced
/// This represents a typical opencode.json structure
fn sample_opencode_json() -> Json {
  {
    "$schema": "https://opencode.ai/config.json",
    "provider": {
      "existing-provider": {
        "npm": "@ai-sdk/anthropic",
        "name": "Existing Provider",
        "options": {
          "baseURL": "https://existing.example.com/api",
          "apiKey": "sk-existing-api-key",
        },
        "models": {
          "existing-model": {
            "name": "Existing Model",
            "modalities": { "input": ["text"], "output": ["text"] },
            "limit": { "context": 1000000.0, "output": 65536.0 },
          },
        },
      },
      "another-provider": {
        "npm": "@ai-sdk/openai",
        "name": "Another Provider",
        "options": {
          "baseURL": "https://another.example.com/api",
          "apiKey": "sk-another-api-key",
        },
        "models": {
          "gpt-4": {
            "name": "GPT-4",
            "modalities": { "input": ["text"], "output": ["text"] },
            "limit": { "context": 8192.0, "output": 4096.0 },
          },
        },
      },
    },
    "other-settings": { "theme": "dark", "autoSave": true },
  }
}

///|
/// Expected other-settings JSON for comparison
fn expected_other_settings() -> Json {
  { "theme": "dark", "autoSave": true }
}

///|
test "apply_provider_to_json - adds new provider and preserves all other properties" {
  // Create a provider with 2 models
  let provider = @provider.Provider::{
    name: "new-provider",
    api_key: "sk-new-provider-api-key",
    openai_base_url: None,
    anthropic_base_url: Some("https://new-provider.example.com/api/v1"),
    models: ["model-alpha", "model-beta"],
  }
  let original_json = sample_opencode_json()
  let updated_json = OpenCode::apply_provider_to_json(
    original_json,
    provider,
    Some(Anthropic),
  )

  // Verify the updated JSON structure
  match updated_json {
    {
      "$schema": schema,
      "provider": provider_obj,
      "other-settings": other_settings_obj,
      ..
    } => {
      // Check schema is preserved
      inspect(
        schema,
        content=(
          #|String("https://opencode.ai/config.json")
        ),
      )

      // Check provider structure
      match provider_obj {
        {
          "existing-provider": _,
          "another-provider": _,
          "new-provider": new_provider,
          ..
        } =>
          // Check the new provider
          match new_provider {
            {
              "npm": npm_val,
              "name": name_val,
              "options": options_obj,
              "models": models_obj,
              ..
            } => {
              inspect(
                npm_val,
                content=(
                  #|String("@ai-sdk/anthropic")
                ),
              )
              inspect(
                name_val,
                content=(
                  #|String("new-provider")
                ),
              )

              // Check options
              match options_obj {
                { "baseURL": base_url_val, "apiKey": api_key_val, .. } => {
                  inspect(
                    base_url_val,
                    content=(
                      #|String("https://new-provider.example.com/api/v1")
                    ),
                  )
                  inspect(
                    api_key_val,
                    content=(
                      #|String("sk-new-provider-api-key")
                    ),
                  )
                }
                _ => fail("options structure mismatch")
              }

              // Check models
              match models_obj {
                { "model-alpha": model_alpha, "model-beta": _, .. } =>
                  // Verify model-alpha exists with correct structure
                  match model_alpha {
                    { "name": model_name_val, "modalities": _, .. } =>
                      inspect(
                        model_name_val,
                        content=(
                          #|String("model-alpha")
                        ),
                      )
                    _ =>
                      fail(
                        "model-alpha structure mismatch, actual: \{model_alpha}",
                      )
                  }
                _ => fail("models structure mismatch")
              }
            }
            _ => fail("new-provider structure mismatch")
          }
        _ => fail("provider object missing expected keys")
      }

      // Verify other-settings are preserved using assert_eq
      assert_eq(other_settings_obj, expected_other_settings())
    }
    _ => fail("root structure mismatch")
  }
}

///|
test "apply_provider_to_json - updates existing provider" {
  let provider = @provider.Provider::{
    name: "existing-provider",
    api_key: "sk-updated-api-key",
    openai_base_url: None,
    anthropic_base_url: Some("https://updated.example.com/api"),
    models: ["new-model-1", "new-model-2"],
  }
  let original_json = sample_opencode_json()
  let updated_json = OpenCode::apply_provider_to_json(
    original_json,
    provider,
    Some(Anthropic),
  )
  match updated_json {
    { "provider": provider_obj, .. } =>
      match provider_obj {
        { "existing-provider": existing_provider, .. } =>
          match existing_provider {
            {
              "npm": npm_val,
              "name": name_val,
              "options": options_obj,
              "models": models_obj,
              ..
            } => {
              inspect(
                npm_val,
                content=(
                  #|String("@ai-sdk/anthropic")
                ),
              )
              inspect(
                name_val,
                content=(
                  #|String("existing-provider")
                ),
              )
              match options_obj {
                { "baseURL": base_url_val, "apiKey": api_key_val, .. } => {
                  inspect(
                    base_url_val,
                    content=(
                      #|String("https://updated.example.com/api")
                    ),
                  )
                  inspect(
                    api_key_val,
                    content=(
                      #|String("sk-updated-api-key")
                    ),
                  )
                }
                _ => fail("options structure mismatch")
              }
              match models_obj {
                { "new-model-1": _, "new-model-2": _, .. } =>
                  // Both new models should exist
                  inspect("both models exist", content="both models exist")
                _ => fail("models structure mismatch")
              }
            }
            _ => fail("existing-provider structure mismatch")
          }
        _ => fail("provider structure mismatch")
      }
    _ => fail("root structure mismatch")
  }
}

///|
test "apply_provider_to_json - raises error when no base URL is provided" {
  let provider = @provider.Provider::{
    name: "no-base-url-provider",
    api_key: "some-key",
    openai_base_url: None,
    anthropic_base_url: None,
    models: ["model-1"],
  }
  let original_json = sample_opencode_json()
  let result = try? OpenCode::apply_provider_to_json(
    original_json,
    provider,
    Some(Anthropic),
  )
  match result {
    Err(_) =>
      inspect("error raised as expected", content="error raised as expected")
    Ok(_) => fail("should have raised error")
  }
}

///|
test "apply_provider_to_json - raises error when models is empty" {
  let provider = @provider.Provider::{
    name: "no-models-provider",
    api_key: "some-key",
    openai_base_url: Some("https://openai.example.com/v1"),
    anthropic_base_url: None,
    models: [],
  }
  let original_json = sample_opencode_json()
  let result = try? OpenCode::apply_provider_to_json(
    original_json,
    provider,
    Some(Anthropic),
  )
  match result {
    Err(_) =>
      inspect("error raised as expected", content="error raised as expected")
    Ok(_) => fail("should have raised error")
  }
}

///|
test "apply_provider_to_json - works with empty JSON (creates new structure)" {
  let empty_json : Json = Json::object(Map::new())
  let provider = @provider.Provider::{
    name: "test-provider",
    api_key: "new-key",
    openai_base_url: None,
    anthropic_base_url: Some("https://new.example.com/api"),
    models: ["test-model"],
  }
  let updated_json = OpenCode::apply_provider_to_json(
    empty_json,
    provider,
    Some(Anthropic),
  )

  // Verify the structure is created properly
  match updated_json {
    { "$schema": schema, "provider": provider_obj, .. } => {
      inspect(
        schema,
        content=(
          #|String("https://opencode.ai/config.json")
        ),
      )
      match provider_obj {
        { "test-provider": _, .. } =>
          inspect("provider exists", content="provider exists")
        _ => fail("provider missing")
      }
    }
    _ => fail("root structure mismatch")
  }
}

///|
test "apply_provider_to_json - OpenAI API format" {
  let provider = @provider.Provider::{
    name: "openai-provider",
    api_key: "sk-openai-key",
    openai_base_url: Some("https://api.openai.com/v1"),
    anthropic_base_url: None,
    models: ["gpt-4", "gpt-3.5-turbo"],
  }
  let original_json = sample_opencode_json()
  let updated_json = OpenCode::apply_provider_to_json(
    original_json,
    provider,
    Some(OpenAI),
  )
  match updated_json {
    { "provider": provider_obj, .. } =>
      match provider_obj {
        { "openai-provider": openai_provider, .. } =>
          match openai_provider {
            { "npm": npm_val, "options": options_obj, "models": models_obj, .. } => {
              inspect(
                npm_val,
                content=(
                  #|String("@ai-sdk/openai-compatible")
                ),
              )
              match options_obj {
                { "baseURL": base_url_val, .. } =>
                  inspect(
                    base_url_val,
                    content=(
                      #|String("https://api.openai.com/v1")
                    ),
                  )
                _ => fail("options structure mismatch")
              }
              match models_obj {
                { "gpt-4": _, "gpt-3.5-turbo": _, .. } =>
                  inspect("both models exist", content="both models exist")
                _ => fail("models structure mismatch")
              }
            }
            _ => fail("openai-provider structure mismatch")
          }
        _ => fail("provider structure mismatch")
      }
    _ => fail("root structure mismatch")
  }
}

///|
test "apply_provider_to_json - None api_format (defaults to OpenAI with anthropic_base_url)" {
  let provider = @provider.Provider::{
    name: "default-provider",
    api_key: "sk-default-key",
    openai_base_url: None,
    anthropic_base_url: Some("https://anthropic.example.com/v1"),
    models: ["claude-3-opus"],
  }
  let original_json = sample_opencode_json()
  let updated_json = OpenCode::apply_provider_to_json(
    original_json,
    provider,
    None,
  )
  match updated_json {
    { "provider": provider_obj, .. } =>
      match provider_obj {
        { "default-provider": default_provider, .. } =>
          match default_provider {
            { "npm": npm_val, "options": options_obj, .. } => {
              inspect(
                npm_val,
                content=(
                  #|String("@ai-sdk/openai-compatible")
                ),
              )
              match options_obj {
                { "baseURL": base_url_val, .. } =>
                  inspect(
                    base_url_val,
                    content=(
                      #|String("https://anthropic.example.com/v1")
                    ),
                  )
                _ => fail("options structure mismatch")
              }
            }
            _ => fail("default-provider structure mismatch")
          }
        _ => fail("provider structure mismatch")
      }
    _ => fail("root structure mismatch")
  }
}

///|
test "apply_provider_to_json - None api_format uses openai_base_url when anthropic not available" {
  let provider = @provider.Provider::{
    name: "fallback-provider",
    api_key: "sk-fallback-key",
    openai_base_url: Some("https://fallback.example.com/v1"),
    anthropic_base_url: None,
    models: ["fallback-model"],
  }
  let original_json = sample_opencode_json()
  let updated_json = OpenCode::apply_provider_to_json(
    original_json,
    provider,
    None,
  )
  match updated_json {
    { "provider": provider_obj, .. } =>
      match provider_obj {
        { "fallback-provider": fallback_provider, .. } =>
          match fallback_provider {
            { "options": options_obj, .. } =>
              match options_obj {
                { "baseURL": base_url_val, .. } =>
                  inspect(
                    base_url_val,
                    content=(
                      #|String("https://fallback.example.com/v1")
                    ),
                  )
                _ => fail("options structure mismatch")
              }
            _ => fail("fallback-provider structure mismatch")
          }
        _ => fail("provider structure mismatch")
      }
    _ => fail("root structure mismatch")
  }
}

///|
test "create_model_entry - creates correct model structure" {
  let model_entry = OpenCode::create_model_entry("test-model-123")
  match model_entry {
    { "name": name_val, "modalities": modalities_obj, .. } => {
      inspect(
        name_val,
        content=(
          #|String("test-model-123")
        ),
      )
      match modalities_obj {
        { "input": input_arr, "output": output_arr, .. } => {
          inspect(
            input_arr,
            content=(
              #|Array([String("text")])
            ),
          )
          inspect(
            output_arr,
            content=(
              #|Array([String("text")])
            ),
          )
        }
        _ => fail("modalities structure mismatch")
      }
    }
    _ => fail("model entry structure mismatch")
  }
}

///|
test "get_config_file_path - returns correct path" {
  let path = OpenCode::get_config_file_path()
  assert_true(path.has_suffix("/opencode.json"))
}

///|
test "get_config_dir - returns correct directory" {
  let dir = OpenCode::get_config_dir()
  assert_true(dir.has_suffix("/opencode"))
}

///|
test "apply_provider_to_json - preserves schema if already present" {
  let custom_schema_json : Json = {
    "$schema": "https://custom.example.com/schema.json",
    "other": "value",
  }
  let provider = @provider.Provider::{
    name: "schema-provider",
    api_key: "sk-schema-key",
    openai_base_url: Some("https://schema.example.com/v1"),
    anthropic_base_url: None,
    models: ["schema-model"],
  }
  let updated_json = OpenCode::apply_provider_to_json(
    custom_schema_json,
    provider,
    Some(OpenAI),
  )
  match updated_json {
    { "$schema": schema_val, "other": other_val, .. } => {
      inspect(
        schema_val,
        content=(
          #|String("https://custom.example.com/schema.json")
        ),
      )
      inspect(
        other_val,
        content=(
          #|String("value")
        ),
      )
    }
    _ => fail("schema was not preserved")
  }
}
