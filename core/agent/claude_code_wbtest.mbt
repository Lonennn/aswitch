///|
/// Whitebox tests for Claude Code agent - testing private functions

///|
/// Sample Claude Code configuration with sensitive information replaced
/// This represents a typical settings.json structure
fn sample_settings_json() -> Json {
  {
    "env": {
      "ANTHROPIC_AUTH_TOKEN": "test-api-key-placeholder",
      "ANTHROPIC_BASE_URL": "https://test.example.com/api",
      "API_TIMEOUT_MS": "3000000",
      "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
      "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1",
      "ANTHROPIC_DEFAULT_OPUS_MODEL": "test-opus-model",
      "ANTHROPIC_DEFAULT_SONNET_MODEL": "test-sonnet-model",
      "ANTHROPIC_DEFAULT_HAIKU_MODEL": "test-haiku-model",
    },
    "hooks": {
      "Notification": [
        {
          "matcher": "*",
          "hooks": [
            {
              "type": "command",
              "command": "claude-code-notification --sound /path/to/notification.wav",
            },
          ],
        },
      ],
      "Stop": [
        {
          "matcher": "*",
          "hooks": [
            {
              "type": "command",
              "command": "claude-code-notification --sound /path/to/notification.wav",
            },
          ],
        },
      ],
    },
    "enabledPlugins": {
      "code-simplifier@claude-plugins-official": true,
      "feature-dev@claude-plugins-official": true,
      "ralph-loop@claude-plugins-official": true,
    },
    "model": "opus",
  }
}

///|
/// Expected hooks JSON for comparison
fn expected_hooks() -> Json {
  {
    "Notification": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "claude-code-notification --sound /path/to/notification.wav",
          },
        ],
      },
    ],
    "Stop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "claude-code-notification --sound /path/to/notification.wav",
          },
        ],
      },
    ],
  }
}

///|
/// Expected enabledPlugins JSON for comparison
fn expected_plugins() -> Json {
  {
    "code-simplifier@claude-plugins-official": true,
    "feature-dev@claude-plugins-official": true,
    "ralph-loop@claude-plugins-official": true,
  }
}

///|
test "apply_provider_to_json - updates env and preserves all other properties" {
  // Create a provider with 3 models
  let provider = @provider.Provider::{
    name: "test-provider",
    api_key: "new-api-key-12345",
    openai_base_url: None,
    anthropic_base_url: Some("https://new-provider.example.com/api/v1"),
    models: ["new-opus", "new-sonnet", "new-haiku"],
  }
  let original_json = sample_settings_json()
  let updated_json = apply_provider_to_json(original_json, provider)

  // Verify the updated JSON structure
  match updated_json {
    {
      "env": env_obj,
      "hooks": hooks_obj,
      "enabledPlugins": plugins_obj,
      "model": model_val,
      ..
    } => {
      // Check env values are updated correctly
      match env_obj {
        {
          "ANTHROPIC_AUTH_TOKEN": auth_token,
          "ANTHROPIC_BASE_URL": base_url,
          "ANTHROPIC_DEFAULT_OPUS_MODEL": opus_model,
          "ANTHROPIC_DEFAULT_SONNET_MODEL": sonnet_model,
          "ANTHROPIC_DEFAULT_HAIKU_MODEL": haiku_model,
          "API_TIMEOUT_MS": timeout,
          "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": disable_traffic,
          "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": experimental,
          ..
        } => {
          // Verify updated values
          inspect(
            auth_token,
            content=(
              #|String("new-api-key-12345")
            ),
          )
          inspect(
            base_url,
            content=(
              #|String("https://new-provider.example.com/api/v1")
            ),
          )
          inspect(
            opus_model,
            content=(
              #|String("new-opus")
            ),
          )
          inspect(
            sonnet_model,
            content=(
              #|String("new-sonnet")
            ),
          )
          inspect(
            haiku_model,
            content=(
              #|String("new-haiku")
            ),
          )

          // Verify preserved env values
          inspect(
            timeout,
            content=(
              #|String("3000000")
            ),
          )
          inspect(
            disable_traffic,
            content=(
              #|String("1")
            ),
          )
          inspect(
            experimental,
            content=(
              #|String("1")
            ),
          )
        }
        _ => fail("env structure mismatch")
      }

      // Verify hooks are preserved using assert_eq
      assert_eq(hooks_obj, expected_hooks())

      // Verify enabledPlugins are preserved using assert_eq
      assert_eq(plugins_obj, expected_plugins())

      // Verify model is preserved using assert_eq
      assert_eq(model_val, Json::string("opus"))
    }
    _ => fail("root structure mismatch")
  }
}

///|
test "apply_provider_to_json - with 2 models uses last model for sonnet and haiku" {
  // Create a provider with only 2 models
  let provider = @provider.Provider::{
    name: "two-model-provider",
    api_key: "two-model-key",
    openai_base_url: None,
    anthropic_base_url: Some("https://two-model.example.com/api"),
    models: ["model-a", "model-b"],
  }
  let original_json = sample_settings_json()
  let updated_json = apply_provider_to_json(original_json, provider)
  match updated_json {
    {
      "env": env_obj,
      "hooks": hooks_obj,
      "enabledPlugins": plugins_obj,
      "model": model_val,
      ..
    } =>
      match env_obj {
        {
          "ANTHROPIC_AUTH_TOKEN": auth_token,
          "ANTHROPIC_BASE_URL": base_url,
          "ANTHROPIC_DEFAULT_OPUS_MODEL": opus_model,
          "ANTHROPIC_DEFAULT_SONNET_MODEL": sonnet_model,
          "ANTHROPIC_DEFAULT_HAIKU_MODEL": haiku_model,
          ..
        } => {
          inspect(
            auth_token,
            content=(
              #|String("two-model-key")
            ),
          )
          inspect(
            base_url,
            content=(
              #|String("https://two-model.example.com/api")
            ),
          )
          inspect(
            opus_model,
            content=(
              #|String("model-a")
            ),
          )
          // With 2 models: sonnet = models[1], haiku = models[last] = models[1]
          inspect(
            sonnet_model,
            content=(
              #|String("model-b")
            ),
          )
          inspect(
            haiku_model,
            content=(
              #|String("model-b")
            ),
          )

          // Verify other properties are preserved using assert_eq
          assert_eq(hooks_obj, expected_hooks())
          assert_eq(plugins_obj, expected_plugins())
          assert_eq(model_val, Json::string("opus"))
        }
        _ => fail("env structure mismatch")
      }
    _ => fail("root structure mismatch")
  }
}

///|
test "apply_provider_to_json - with 1 model uses same model for all" {
  // Create a provider with only 1 model
  let provider = @provider.Provider::{
    name: "single-model-provider",
    api_key: "single-model-key",
    openai_base_url: None,
    anthropic_base_url: Some("https://single.example.com/api"),
    models: ["only-model"],
  }
  let original_json = sample_settings_json()
  let updated_json = apply_provider_to_json(original_json, provider)
  match updated_json {
    {
      "env": env_obj,
      "hooks": hooks_obj,
      "enabledPlugins": plugins_obj,
      "model": model_val,
      ..
    } =>
      match env_obj {
        {
          "ANTHROPIC_DEFAULT_OPUS_MODEL": opus_model,
          "ANTHROPIC_DEFAULT_SONNET_MODEL": sonnet_model,
          "ANTHROPIC_DEFAULT_HAIKU_MODEL": haiku_model,
          ..
        } => {
          // With 1 model: all use models[0]
          inspect(
            opus_model,
            content=(
              #|String("only-model")
            ),
          )
          inspect(
            sonnet_model,
            content=(
              #|String("only-model")
            ),
          )
          inspect(
            haiku_model,
            content=(
              #|String("only-model")
            ),
          )

          // Verify other properties are preserved using assert_eq
          assert_eq(hooks_obj, expected_hooks())
          assert_eq(plugins_obj, expected_plugins())
          assert_eq(model_val, Json::string("opus"))
        }
        _ => fail("env structure mismatch")
      }
    _ => fail("root structure mismatch")
  }
}

///|
test "apply_provider_to_json - raises error when anthropic_base_url is None" {
  let provider = @provider.Provider::{
    name: "no-base-url-provider",
    api_key: "some-key",
    openai_base_url: Some("https://openai.example.com/v1"),
    anthropic_base_url: None,
    models: ["model-1"],
  }
  let original_json = sample_settings_json()
  let result = try? apply_provider_to_json(original_json, provider)
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
    openai_base_url: None,
    anthropic_base_url: Some("https://example.com/api"),
    models: [],
  }
  let original_json = sample_settings_json()
  let result = try? apply_provider_to_json(original_json, provider)
  match result {
    Err(_) =>
      inspect("error raised as expected", content="error raised as expected")
    Ok(_) => fail("should have raised error")
  }
}

///|
test "apply_provider_to_json - works with minimal settings (no hooks/plugins)" {
  let minimal_json : Json = {
    "env": {
      "ANTHROPIC_AUTH_TOKEN": "old-key",
      "ANTHROPIC_BASE_URL": "https://old.example.com",
    },
    "model": "sonnet",
  }
  let provider = @provider.Provider::{
    name: "test-provider",
    api_key: "new-key",
    openai_base_url: None,
    anthropic_base_url: Some("https://new.example.com/api"),
    models: ["opus-model", "sonnet-model", "haiku-model"],
  }
  let updated_json = apply_provider_to_json(minimal_json, provider)

  // Verify the minimal structure is preserved and updated
  match updated_json {
    { "env": env_obj, "model": model_val, .. } => {
      match env_obj {
        {
          "ANTHROPIC_AUTH_TOKEN": auth_token,
          "ANTHROPIC_BASE_URL": base_url,
          "ANTHROPIC_DEFAULT_OPUS_MODEL": opus_model,
          "ANTHROPIC_DEFAULT_SONNET_MODEL": sonnet_model,
          "ANTHROPIC_DEFAULT_HAIKU_MODEL": haiku_model,
          ..
        } => {
          inspect(
            auth_token,
            content=(
              #|String("new-key")
            ),
          )
          inspect(
            base_url,
            content=(
              #|String("https://new.example.com/api")
            ),
          )
          inspect(
            opus_model,
            content=(
              #|String("opus-model")
            ),
          )
          inspect(
            sonnet_model,
            content=(
              #|String("sonnet-model")
            ),
          )
          inspect(
            haiku_model,
            content=(
              #|String("haiku-model")
            ),
          )
        }
        _ => fail("env structure mismatch")
      }
      // model should be preserved using assert_eq
      assert_eq(model_val, Json::string("sonnet"))
    }
    _ => fail("root structure mismatch")
  }
}
