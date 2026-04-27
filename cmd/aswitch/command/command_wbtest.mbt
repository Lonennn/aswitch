// This impl Show for Command is strange, but if we impl this in the command.mbt the build system will warn.

///|
impl Show for Command with output(self, logger) -> Unit {
  logger.write_string(self.to_repr().to_string())
}

///|
test "parse_args maps providers and legacy aliases to list providers" {
  assert_true(parse_args(["providers"]) is ListProviders)
  assert_true(parse_args(["list"]) is ListProviders)
  assert_true(parse_args(["ls"]) is ListProviders)
}

///|
test "parse_args maps agents to list agents" {
  assert_true(parse_args(["agents"]) is ListAgents)
}

///|
test "parse_args maps add to interactive and positional variants" {
  assert_true(parse_args(["add"]) is AddProviderInteractive)
  match
    parse_args([
      "add", "openai", "sk-xxx", "https://api.openai.com/v1", "gpt-4o",
    ]) {
    AddProvider(name~, api_key~, model~, openai_base_url~, anthropic_base_url~) => {
      assert_eq(name, "openai")
      assert_eq(api_key, "sk-xxx")
      assert_eq(model, "gpt-4o")
      assert_true(openai_base_url is Some("https://api.openai.com/v1"))
      assert_true(anthropic_base_url is None)
    }
    other => fail("Expected AddProvider, got \{other}")
  }
}

///|
test "parse_args maps add option mode for anthropic-only and dual URLs" {
  match
    parse_args([
      "add", "--name", "anthropic", "--api-key", "sk-ant", "--model", "claude-3-7-sonnet",
      "--anthropic-base-url", "https://api.anthropic.com",
    ]) {
    AddProvider(name~, api_key~, model~, openai_base_url~, anthropic_base_url~) => {
      assert_eq(name, "anthropic")
      assert_eq(api_key, "sk-ant")
      assert_eq(model, "claude-3-7-sonnet")
      assert_true(openai_base_url is None)
      assert_true(anthropic_base_url is Some("https://api.anthropic.com"))
    }
    other => fail("Expected AddProvider, got \{other}")
  }

  match
    parse_args([
      "add", "--name", "both", "--api-key", "sk-both", "--model", "gpt-4.1", "--openai-base-url",
      "https://api.openai.com/v1", "--anthropic-base-url", "https://api.anthropic.com",
    ]) {
    AddProvider(name~, api_key~, model~, openai_base_url~, anthropic_base_url~) => {
      assert_eq(name, "both")
      assert_eq(api_key, "sk-both")
      assert_eq(model, "gpt-4.1")
      assert_true(openai_base_url is Some("https://api.openai.com/v1"))
      assert_true(anthropic_base_url is Some("https://api.anthropic.com"))
    }
    other => fail("Expected AddProvider, got \{other}")
  }
}

///|
test "parse_args add option mode validates required fields" {
  match parse_args(["add", "--name", "x", "--api-key", "k", "--model", "m"]) {
    ErrorParameter(err) => assert_true(err.contains("at least one base URL"))
    other => fail("Expected ErrorParameter, got \{other}")
  }
}

///|
test "parse_args maps remove aliases and ignores extra args" {
  match parse_args(["remove", "openai"]) {
    RemoveProvider(name) => assert_eq(name, "openai")
    other => fail("Expected RemoveProvider, got \{other}")
  }

  match parse_args(["rm", "anthropic", "ignored", "extra"]) {
    RemoveProvider(name) => assert_eq(name, "anthropic")
    other => fail("Expected RemoveProvider, got \{other}")
  }
}

///|
test "set_provider fails with invalid config" {
  // Setup: Create invalid config with duplicate provider names
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
    openai_base_url: Some("https://api.openai.com/v1"),
    anthropic_base_url: None,
    models: [@provider.Model::new(name="gpt-4o", context_limit=128000)],
  }

  let config = @core.Config::{
    providers: @list.from_array([provider1, provider2]),
  }

  // Create 100% isolated temporary directory for test config - NO RISK to user data
  let original_home = @sys.get_env_var("ASWITCH_HOME")
  // Use unique directory name that will never conflict with user files
  let temp_dir = "_aswitch_test_temp_config"
  // Create temp directory (will fail if already exists, which is safe)
  try! @fs.create_dir(temp_dir)
  defer {
    // Clean up all temp files automatically
    let temp_config_path = @path.Path(temp_dir)
      .join(@core.CONFIG_FILE_NAME)
      .to_string()
    let _ = try? @fs.remove_file(temp_config_path)
    let _ = try? @fs.remove_dir(temp_dir)
    // Restore original environment
    @sys.set_env_var("ASWITCH_HOME", original_home.unwrap_or(""))
  }
  @sys.set_env_var("ASWITCH_HOME", temp_dir)

  // Save test config to ISOLATED temp directory - never touches user's real config
  @core.save_config(config).unwrap()

  // Run set_provider
  let result = set_provider("claudecode", "openai", None, false)
  assert_eq(result, EXIT_CODE_CONFIG_ERROR)
}

///|
test "parse_args correctly parses dry-run flags" {
  // Test long form --dry-run
  match parse_args(["set", "claudecode", "openai", "--dry-run"]) {
    SetProvider(agent~, provider~, api_format~, dry_run~) => {
      assert_eq(agent, "claudecode")
      assert_eq(provider, "openai")
      assert_true(api_format is None)
      assert_true(dry_run)
    }
    other => fail("Expected SetProvider, got \{other}")
  }

  // Test short form -n
  match parse_args(["switch", "open-code", "anthropic", "-n"]) {
    SetProvider(agent~, provider~, api_format~, dry_run~) => {
      assert_eq(agent, "open-code")
      assert_eq(provider, "anthropic")
      assert_true(api_format is None)
      assert_true(dry_run)
    }
    other => fail("Expected SetProvider, got \{other}")
  }

  // Test dry-run flag anywhere in args
  match parse_args(["set", "--dry-run", "openclaw", "openai", "openai"]) {
    SetProvider(agent~, provider~, api_format~, dry_run~) => {
      assert_eq(agent, "openclaw")
      assert_eq(provider, "openai")
      assert_true(api_format is Some(@agent.OpenAI))
      assert_true(dry_run)
    }
    other => fail("Expected SetProvider, got \{other}")
  }

  // Test no dry-run flag defaults to false
  match parse_args(["set", "claudecode", "openai"]) {
    SetProvider(agent~, provider~, api_format~, dry_run~) => {
      assert_eq(agent, "claudecode")
      assert_eq(provider, "openai")
      assert_true(api_format is None)
      assert_false(dry_run)
    }
    other => fail("Expected SetProvider, got \{other}")
  }
}

///|
fn cleanup_command_temp_dir(temp_dir : String) -> Unit {
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
      cleanup_command_temp_dir(child_path)
    }
  }
  let _ = try? @fs.remove_dir(temp_dir)
}

///|
fn command_with_temp_aswitch_home(
  temp_dir : String,
  body : () -> Unit raise Error,
) -> Unit raise Error {
  let original_home = @sys.get_env_var("ASWITCH_HOME")
  cleanup_command_temp_dir(temp_dir)
  try! @fs.create_dir(temp_dir)
  @sys.set_env_var("ASWITCH_HOME", temp_dir)
  defer {
    cleanup_command_temp_dir(temp_dir)
    match original_home {
      Some(home) => @sys.set_env_var("ASWITCH_HOME", home)
      None => @sys.unset_env_var("ASWITCH_HOME")
    }
  }
  body()
}

///|
fn command_with_temp_xdg_config_home(
  temp_dir : String,
  body : () -> Unit raise Error,
) -> Unit raise Error {
  let original_home = @sys.get_env_var("HOME")
  let original_xdg = @sys.get_env_var("XDG_CONFIG_HOME")
  cleanup_command_temp_dir(temp_dir)
  try! @fs.create_dir(temp_dir)
  @sys.set_env_var("HOME", temp_dir)
  @sys.set_env_var("XDG_CONFIG_HOME", temp_dir)
  defer {
    cleanup_command_temp_dir(temp_dir)
    match original_home {
      Some(home) => @sys.set_env_var("HOME", home)
      None => @sys.unset_env_var("HOME")
    }
    match original_xdg {
      Some(xdg) => @sys.set_env_var("XDG_CONFIG_HOME", xdg)
      None => @sys.unset_env_var("XDG_CONFIG_HOME")
    }
  }
  body()
}

///|
fn write_test_config(providers : Array[@provider.Provider]) -> Unit {
  let config = @core.Config::{ providers: @list.from_array(providers) }
  @core.save_config(config).unwrap()
}

///|
test "parse_args maps temporary command and exec variants" {
  match
    parse_args(["command", "claude-code", "seed", "--api-format", "anthropic"]) {
    TemporaryCommand(agent~, provider~, api_format~) => {
      assert_eq(agent, "claude-code")
      assert_eq(provider, "seed")
      assert_true(api_format is Some(@agent.Anthropic))
    }
    other => fail("Expected TemporaryCommand, got \{other}")
  }

  match
    parse_args([
      "exec", "open-code", "seed", "--api-format", "openai", "--print-command", "--",
      "opencode", "run",
    ]) {
    TemporaryExec(agent~, provider~, api_format~, command~, print_command~) => {
      assert_eq(agent, "open-code")
      assert_eq(provider, "seed")
      assert_true(api_format is Some(@agent.OpenAI))
      assert_eq(command, ["opencode", "run"])
      assert_true(print_command)
    }
    other => fail("Expected TemporaryExec, got \{other}")
  }

  match parse_args(["exec", "claude-code", "seed"]) {
    TemporaryExec(agent~, provider~, api_format~, command~, print_command~) => {
      assert_eq(agent, "claude-code")
      assert_eq(provider, "seed")
      assert_true(api_format is None)
      assert_eq(command, [])
      assert_false(print_command)
    }
    other => fail("Expected TemporaryExec, got \{other}")
  }
}

///|
async test "render_temporary_command renders claude override from isolated config" {
  command_with_temp_aswitch_home("_aswitch_test_temp_command_claude", fn() raise {
    write_test_config([
      @provider.Provider::{
        name: "seed",
        api_key: "sk-test-'quoted'",
        openai_base_url: None,
        anthropic_base_url: Some("https://seed.example.com/anthropic"),
        models: [
          @provider.Model::new(name="seed-opus"),
          @provider.Model::new(name="seed-sonnet"),
          @provider.Model::new(name="seed-haiku"),
        ],
      },
    ])

    let rendered = render_temporary_command("claude", "seed", None).unwrap()
    inspect(
      rendered.command,
      content=(
        #|ANTHROPIC_AUTH_TOKEN='sk-test-'"'"'quoted'' ANTHROPIC_BASE_URL='https://seed.example.com/anthropic' ANTHROPIC_DEFAULT_OPUS_MODEL='seed-opus' ANTHROPIC_DEFAULT_SONNET_MODEL='seed-sonnet' ANTHROPIC_DEFAULT_HAIKU_MODEL='seed-haiku' claude
      ),
    )
  })
}

///|
async test "render_temporary_command renders opencode override with config content" {
  command_with_temp_aswitch_home("_aswitch_test_temp_command_opencode", fn() raise {
    command_with_temp_xdg_config_home(
      "_aswitch_test_temp_xdg_command_opencode",
      fn() raise {
        write_test_config([
          @provider.Provider::{
            name: "seed",
            api_key: "sk-opencode",
            openai_base_url: Some("https://seed.example.com/openai"),
            anthropic_base_url: Some("https://seed.example.com/anthropic"),
            models: [@provider.Model::new(name="seed-model")],
          },
        ])

        let rendered = render_temporary_command(
          "open-code",
          "seed",
          Some(@agent.OpenAI),
        ).unwrap()
        inspect(
          rendered.command,
          content=(
            #|OPENCODE_CONFIG_CONTENT='{
            #|  "provider": {
            #|    "seed": {
            #|      "npm": "@ai-sdk/openai-compatible",
            #|      "name": "seed",
            #|      "options": {
            #|        "apiKey": "sk-opencode",
            #|        "baseURL": "https://seed.example.com/openai"
            #|      },
            #|      "models": {
            #|        "seed-model": {
            #|          "name": "seed-model"
            #|        }
            #|      }
            #|    }
            #|  },
            #|  "$schema": "https://opencode.ai/config.json"
            #|}' opencode
          ),
        )
      },
    )
  })
}

///|
test "temporary_command rejects openclaw render-only workflow" {
  command_with_temp_aswitch_home("_aswitch_test_temp_command_openclaw", fn() raise {
    write_test_config([
      @provider.Provider::{
        name: "seed",
        api_key: "sk-openclaw",
        openai_base_url: Some("https://seed.example.com/openai"),
        anthropic_base_url: None,
        models: [@provider.Model::new(name="seed-model")],
      },
    ])

    let status = temporary_command("openclaw", "seed", Some(@agent.OpenAI))
    assert_eq(status, EXIT_CODE_CONFIG_ERROR)
  })
}
