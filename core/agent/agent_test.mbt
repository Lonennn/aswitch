///|
test "supported_agents returns canonical agent names" {
  assert_eq(supported_agents(), ["claude-code", "open-code", "openclaw"])
}

///|
test "get_agent_config_path returns correct path for supported agents" {
  // Build expected path parts using the core library
  let claude_part = @path.Path::join(".claude", "settings.json").to_string()
  let opencode_part = @path.Path::join("opencode", "opencode.json").to_string()
  let openclaw_part = @path.Path::join(".openclaw", "openclaw.json").to_string()

  assert_true(
    get_agent_config_path("claude-code").unwrap().contains(claude_part),
  )
  assert_true(get_agent_config_path("claude").unwrap().contains(claude_part))
  assert_true(
    get_agent_config_path("claudecode").unwrap().contains(claude_part),
  )

  assert_true(
    get_agent_config_path("open-code").unwrap().contains(opencode_part),
  )
  assert_true(
    get_agent_config_path("opencode").unwrap().contains(opencode_part),
  )

  assert_true(
    get_agent_config_path("openclaw").unwrap().contains(openclaw_part),
  )
  assert_true(
    get_agent_config_path("open-claw").unwrap().contains(openclaw_part),
  )
}

///|
test "get_agent_config_path returns None for unsupported agents" {
  assert_eq(get_agent_config_path("invalid"), None)
  assert_eq(get_agent_config_path("cursor"), None)
  assert_eq(get_agent_config_path(""), None)
}

///|
test "is_agent_installed returns false for unsupported agents" {
  assert_false(is_agent_installed("invalid"))
  assert_false(is_agent_installed("cursor"))
}

///|
fn cleanup_temp_dir(temp_dir : String) -> Unit {
  if !@fs.path_exists(temp_dir) {
    return ()
  }
  let entries_result = try? @fs.read_dir(temp_dir)
  guard entries_result is Ok(entries) else {
    // If we can't read the dir, try to remove it anyway
    let _ = try? @fs.remove_dir(temp_dir)
    return ()
  }
  for entry in entries {
    let file_path = @path.Path(temp_dir).join(entry).to_string()
    // Try to remove as file first, then as dir
    let remove_result = try? @fs.remove_file(file_path)
    if remove_result is Err(_) {
      cleanup_temp_dir(file_path)
    }
  }
  let _ = try? @fs.remove_dir(temp_dir)
}

///|
test "is_agent_installed returns true when Claude Code config file exists" {
  // Save original HOME
  let original_home = @sys.get_env_var("HOME")

  // Create temporary directory
  let temp_home = "_aswitch_test_claude_installed"
  cleanup_temp_dir(temp_home)
  try! @fs.create_dir(temp_home)
  @sys.set_env_var("HOME", temp_home)

  // Create .claude directory and settings.json
  let claude_dir = @path.Path(temp_home).join(".claude").to_string()
  try! @fs.create_dir(claude_dir)
  let config_path = @path.Path(claude_dir).join("settings.json").to_string()
  try! @fs.write_string_to_file(config_path, "{}")

  // Test the function
  assert_true(is_agent_installed("claude-code"))
  assert_true(is_agent_installed("claude"))
  assert_true(is_agent_installed("claudecode"))

  // Clean up
  try! @fs.remove_file(config_path)
  try! @fs.remove_dir(claude_dir)
  cleanup_temp_dir(temp_home)

  // Restore original HOME
  match original_home {
    Some(home) => @sys.set_env_var("HOME", home)
    None => @sys.unset_env_var("HOME")
  }
}

///|
test "is_agent_installed returns false when Claude Code config file does not exist" {
  // Save original HOME
  let original_home = @sys.get_env_var("HOME")

  // Create temporary directory
  let temp_home = "_aswitch_test_claude_not_installed"
  cleanup_temp_dir(temp_home)
  try! @fs.create_dir(temp_home)
  @sys.set_env_var("HOME", temp_home)

  // Ensure .claude directory doesn't exist
  let claude_dir = @path.Path(temp_home).join(".claude").to_string()
  if @fs.path_exists(claude_dir) {
    cleanup_temp_dir(claude_dir)
  }

  // Test the function
  assert_false(is_agent_installed("claude-code"))
  assert_false(is_agent_installed("claude"))
  assert_false(is_agent_installed("claudecode"))

  // Clean up
  cleanup_temp_dir(temp_home)

  // Restore original HOME
  match original_home {
    Some(home) => @sys.set_env_var("HOME", home)
    None => @sys.unset_env_var("HOME")
  }
}

///|
test "is_agent_installed returns true when OpenCode config file exists" {
  // Save original HOME and XDG_CONFIG_HOME
  let original_home = @sys.get_env_var("HOME")
  let original_xdg = @sys.get_env_var("XDG_CONFIG_HOME")

  // Create temporary directory
  let temp_home = "_aswitch_test_opencode_installed"
  cleanup_temp_dir(temp_home)
  try! @fs.create_dir(temp_home)
  @sys.set_env_var("HOME", temp_home)
  @sys.unset_env_var("XDG_CONFIG_HOME") // Unset to test default ~/.config path

  // Create .config/opencode directory and opencode.json
  let config_dir = @path.Path(temp_home).join(".config").to_string()
  try! @fs.create_dir(config_dir)
  let opencode_dir = @path.Path(config_dir).join("opencode").to_string()
  try! @fs.create_dir(opencode_dir)
  let config_path = @path.Path(opencode_dir).join("opencode.json").to_string()
  try! @fs.write_string_to_file(config_path, "{}")

  // Test the function
  assert_true(is_agent_installed("open-code"))
  assert_true(is_agent_installed("opencode"))

  // Clean up
  try! @fs.remove_file(config_path)
  try! @fs.remove_dir(opencode_dir)
  try! @fs.remove_dir(config_dir)
  cleanup_temp_dir(temp_home)

  // Restore original environment
  match original_home {
    Some(home) => @sys.set_env_var("HOME", home)
    None => @sys.unset_env_var("HOME")
  }
  match original_xdg {
    Some(xdg) => @sys.set_env_var("XDG_CONFIG_HOME", xdg)
    None => @sys.unset_env_var("XDG_CONFIG_HOME")
  }
}

///|
test "is_agent_installed returns false when OpenCode config file does not exist" {
  // Save original HOME and XDG_CONFIG_HOME
  let original_home = @sys.get_env_var("HOME")
  let original_xdg = @sys.get_env_var("XDG_CONFIG_HOME")

  // Create temporary directory
  let temp_home = "_aswitch_test_opencode_not_installed"
  cleanup_temp_dir(temp_home)
  try! @fs.create_dir(temp_home)
  @sys.set_env_var("HOME", temp_home)
  @sys.unset_env_var("XDG_CONFIG_HOME") // Unset to test default ~/.config path

  // Ensure opencode directory doesn't exist
  let opencode_dir = @path.Path(temp_home)
    .join(".config")
    .join("opencode")
    .to_string()
  if @fs.path_exists(opencode_dir) {
    cleanup_temp_dir(opencode_dir)
  }

  // Test the function
  assert_false(is_agent_installed("open-code"))
  assert_false(is_agent_installed("opencode"))

  // Clean up
  cleanup_temp_dir(temp_home)

  // Restore original environment
  match original_home {
    Some(home) => @sys.set_env_var("HOME", home)
    None => @sys.unset_env_var("HOME")
  }
  match original_xdg {
    Some(xdg) => @sys.set_env_var("XDG_CONFIG_HOME", xdg)
    None => @sys.unset_env_var("XDG_CONFIG_HOME")
  }
}

///|
test "is_agent_installed returns true when OpenClaw config file exists" {
  // Save original HOME
  let original_home = @sys.get_env_var("HOME")

  // Create temporary directory
  let temp_home = "_aswitch_test_openclaw_installed"
  cleanup_temp_dir(temp_home)
  try! @fs.create_dir(temp_home)
  @sys.set_env_var("HOME", temp_home)

  // Create .openclaw directory and openclaw.json
  let openclaw_dir = @path.Path(temp_home).join(".openclaw").to_string()
  try! @fs.create_dir(openclaw_dir)
  let config_path = @path.Path(openclaw_dir).join("openclaw.json").to_string()
  try! @fs.write_string_to_file(config_path, "{}")

  // Test the function
  assert_true(is_agent_installed("openclaw"))
  assert_true(is_agent_installed("open-claw"))

  // Clean up
  try! @fs.remove_file(config_path)
  try! @fs.remove_dir(openclaw_dir)
  cleanup_temp_dir(temp_home)

  // Restore original HOME
  match original_home {
    Some(home) => @sys.set_env_var("HOME", home)
    None => @sys.unset_env_var("HOME")
  }
}

///|
test "is_agent_installed returns false when OpenClaw config file does not exist" {
  // Save original HOME
  let original_home = @sys.get_env_var("HOME")

  // Create temporary directory
  let temp_home = "_aswitch_test_openclaw_not_installed"
  cleanup_temp_dir(temp_home)
  try! @fs.create_dir(temp_home)
  @sys.set_env_var("HOME", temp_home)

  // Ensure .openclaw directory doesn't exist
  let openclaw_dir = @path.Path(temp_home).join(".openclaw").to_string()
  if @fs.path_exists(openclaw_dir) {
    cleanup_temp_dir(openclaw_dir)
  }

  // Test the function
  assert_false(is_agent_installed("openclaw"))
  assert_false(is_agent_installed("open-claw"))

  // Clean up
  cleanup_temp_dir(temp_home)

  // Restore original HOME
  match original_home {
    Some(home) => @sys.set_env_var("HOME", home)
    None => @sys.unset_env_var("HOME")
  }
}
