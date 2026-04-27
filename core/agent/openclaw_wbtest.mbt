///|
test "OpenClaw get_config_dir returns correct path" {
  // Test that the config directory path is correctly formed
  let path = OpenClaw::get_config_dir()
  assert_true(path.has_suffix(".openclaw"))
}

///|
test "OpenClaw get_config_file_path returns correct path" {
  // Test that the config file path is correctly formed
  let path = OpenClaw::get_config_file_path()
  assert_true(path.has_suffix("openclaw.json"))
}

///|
fn sample_openclaw_json() -> Json {
  {
    "models": {
      "mode": "merge",
      "providers": {
        "existing-provider": {
          "baseUrl": "https://existing.example.com/v1",
          "apiKey": "sk-existing",
          "api": "openai-completions",
          "models": [
            {
              "id": "existing-model",
              "name": "Existing Model",
              "reasoning": false,
              "contextWindow": 16000.0,
              "maxTokens": 4096.0,
              "input": ["text"],
              "cost": {
                "input": 0.0,
                "output": 0.0,
                "cacheRead": 0.0,
                "cacheWrite": 0.0,
              },
            },
          ],
        },
      },
    },
    "agents": {
      "defaults": { "model": { "primary": "existing-provider/existing-model" } },
    },
    "ui": { "theme": "light" },
  }
}

///|
fn cleanup_openclaw_temp_dir(temp_dir : String) -> Unit {
  if !@fs.path_exists(temp_dir) {
    return ()
  }
  let entries_result = try? @fs.read_dir(temp_dir)
  guard entries_result is Ok(entries) else {
    let _ = try? @fs.remove_dir(temp_dir)
    return ()
  }
  for entry in entries {
    let child_path = @path.Path(temp_dir).join(entry).to_string()
    let remove_file_result = try? @fs.remove_file(child_path)
    if remove_file_result is Err(_) {
      cleanup_openclaw_temp_dir(child_path)
    }
  }
  let _ = try? @fs.remove_dir(temp_dir)
}

///|
test "get_temporary_override preserves existing openclaw settings" {
  let original_home = @sys.get_env_var("HOME")
  let temp_home = "_aswitch_test_openclaw_temp_override"
  cleanup_openclaw_temp_dir(temp_home)
  try! @fs.create_dir(temp_home)
  @sys.set_env_var("HOME", temp_home)

  let openclaw_dir = @path.Path(temp_home).join(".openclaw").to_string()
  try! @fs.create_dir(openclaw_dir)
  let config_path = @path.Path(openclaw_dir).join("openclaw.json").to_string()
  try! @fs.write_string_to_file(
    config_path,
    sample_openclaw_json().stringify(indent=2),
  )

  let provider = @provider.Provider::{
    name: "temp-provider",
    api_key: "sk-temp-key",
    openai_base_url: Some("https://temp.example.com/v1"),
    anthropic_base_url: None,
    models: [@provider.Model::new(name="temp-model")],
  }
  let temporary_override = OpenClaw::get_temporary_override(
    OpenClaw::{  },
    provider,
    Some(OpenAI),
  )
  let temp_content = temporary_override.temp_files[0].content
  let json_result = try? @json.parse(temp_content)
  guard json_result is Ok(json) else {
    fail("temporary override should contain valid JSON")
  }
  match json {
    {
      "models": {
        "providers": { "existing-provider": _, "temp-provider": _, .. },
        ..
      },
      "agents": agents,
      "ui": ui,
      ..
    } => {
      assert_eq(agents, {
        "defaults": { "model": { "primary": "temp-provider/temp-model" } },
      })
      assert_eq(ui, { "theme": "light" })
    }
    _ => fail("temporary override should preserve existing OpenClaw settings")
  }

  cleanup_openclaw_temp_dir(temp_home)
  match original_home {
    Some(home) => @sys.set_env_var("HOME", home)
    None => @sys.unset_env_var("HOME")
  }
}
