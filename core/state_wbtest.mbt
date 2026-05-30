///|
/// Whitebox tests for usage state module

///|
test "UsageState::new creates empty state" {
  let state = UsageState::new()
  assert_true(state.last_agent is None)
  assert_true(state.agent_states.is_empty())
}

///|
test "UsageState::set_agent_state updates last_agent and agent_states" {
  let state = UsageState::new()
  state.set_agent_state("claude-code", "OpenAI", Some("anthropic"))
  assert_true(state.last_agent == Some("claude-code"))
  match state.get_agent_state("claude-code") {
    Some(agent_state) => {
      assert_true(agent_state.provider == "OpenAI")
      assert_true(agent_state.api_format == Some("anthropic"))
    }
    None => fail("Expected agent state for claude-code")
  }
}

///|
test "UsageState::get_agent_state returns None for unknown agent" {
  let state = UsageState::new()
  assert_true(state.get_agent_state("unknown") is None)
}

///|
test "load_usage_state returns empty state when file missing" {
  let original_home = @sys.get_env_var("ASWITCH_HOME")
  let temp_dir = "_aswitch_test_state_load_missing"
  try! @fs.create_dir(temp_dir)
  defer {
    let _ = try? @fs.remove_dir(temp_dir)
    match original_home {
      Some(home) => @sys.set_env_var("ASWITCH_HOME", home)
      None => @sys.unset_env_var("ASWITCH_HOME")
    }
  }
  @sys.set_env_var("ASWITCH_HOME", temp_dir)

  let state = load_usage_state()
  assert_true(state.last_agent is None)
  assert_true(state.agent_states.is_empty())
}

///|
test "save and load usage state roundtrip" {
  let original_home = @sys.get_env_var("ASWITCH_HOME")
  let temp_dir = "_aswitch_test_state_roundtrip"
  try! @fs.create_dir(temp_dir)
  defer {
    let state_path = @path.Path(temp_dir).join("state.json").to_string()
    let _ = try? @fs.remove_file(state_path)
    let _ = try? @fs.remove_dir(temp_dir)
    match original_home {
      Some(home) => @sys.set_env_var("ASWITCH_HOME", home)
      None => @sys.unset_env_var("ASWITCH_HOME")
    }
  }
  @sys.set_env_var("ASWITCH_HOME", temp_dir)

  let state = UsageState::new()
  state.set_agent_state("claude-code", "seed", Some("anthropic"))
  state.set_agent_state("open-code", "openai", None)

  save_usage_state(state).unwrap()

  let loaded = load_usage_state()
  assert_true(loaded.last_agent == Some("open-code")) // last set wins
  match loaded.get_agent_state("claude-code") {
    Some(s) => {
      assert_true(s.provider == "seed")
      assert_true(s.api_format == Some("anthropic"))
    }
    None => fail("Expected claude-code state")
  }
  match loaded.get_agent_state("open-code") {
    Some(s) => {
      assert_true(s.provider == "openai")
      assert_true(s.api_format is None)
    }
    None => fail("Expected open-code state")
  }
}

///|
test "ToJson and FromJson for UsageState" {
  let state = UsageState::new()
  state.set_agent_state("claude-code", "seed", Some("anthropic"))

  let json = state.to_json()
  let json_str = json.stringify(indent=2)

  let parsed = try! @json.parse(json_str)
  let restored : UsageState = @json.from_json(parsed)

  assert_true(restored.last_agent == Some("claude-code"))
  match restored.get_agent_state("claude-code") {
    Some(s) => {
      assert_true(s.provider == "seed")
      assert_true(s.api_format == Some("anthropic"))
    }
    None => fail("Expected claude-code state after JSON roundtrip")
  }
}
