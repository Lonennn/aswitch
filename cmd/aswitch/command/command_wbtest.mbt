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
  let result = set_provider("claudecode", "openai", None)
  assert_eq(result, EXIT_CODE_CONFIG_ERROR)
}
