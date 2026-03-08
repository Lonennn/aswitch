///|
/// Claude Code agent implementation that manages ~/.claude/settings.json

///|
pub struct ClaudeCode {}

///|
/// Get the Claude Code configuration file path (~/.claude/settings.json)
fn get_claude_code_config_path() -> String {
  let home = match @sys.get_env_var("HOME") {
    Some(h) => h
    None => "."
  }
  home + "/.claude/settings.json"
}

///|
/// Get the Claude Code directory path (~/.claude)
fn get_claude_code_dir_path() -> String {
  let home = match @sys.get_env_var("HOME") {
    Some(h) => h
    None => "."
  }
  home + "/.claude"
}

///|
/// Apply provider settings to a Json object in memory
/// This function modifies the "env" object within the settings JSON
/// while preserving all other properties
fn apply_provider_to_json(
  settings_json : Json,
  provider : @provider.Provider,
) -> Json raise Error {
  // Get or create the env object
  let env_json = match settings_json {
    { "env": env_obj, .. } => env_obj
    _ => Json::object(Map::new())
  }

  // Convert env to Map for modification
  let env_map : Map[String, Json] = match env_json {
    Json::Object(m) => m
    _ => Map::new()
  }

  // Set API key
  env_map["ANTHROPIC_AUTH_TOKEN"] = Json::string(provider.api_key)

  // Set base URL - anthropic_base_url is required
  let base_url = match provider.anthropic_base_url {
    Some(url) => url
    None =>
      raise ProviderLackUrlError(
        "anthropic_base_url is required for Claude Code agent",
      )
  }
  env_map["ANTHROPIC_BASE_URL"] = Json::string(base_url)

  // Set models - at least one model is required
  let model_count = provider.models.length()
  if model_count == 0 {
    raise ProviderLackUrlError(
      "at least one model is required for Claude Code agent",
    )
  }
  env_map["ANTHROPIC_DEFAULT_OPUS_MODEL"] = Json::string(provider.models[0])
  if model_count > 1 {
    env_map["ANTHROPIC_DEFAULT_SONNET_MODEL"] = Json::string(provider.models[1])
  } else {
    env_map["ANTHROPIC_DEFAULT_SONNET_MODEL"] = Json::string(
      provider.models[model_count - 1],
    )
  }
  if model_count > 2 {
    env_map["ANTHROPIC_DEFAULT_HAIKU_MODEL"] = Json::string(provider.models[2])
  } else {
    env_map["ANTHROPIC_DEFAULT_HAIKU_MODEL"] = Json::string(
      provider.models[model_count - 1],
    )
  }

  // Build the result JSON, preserving other properties
  let result_map : Map[String, Json] = match settings_json {
    Json::Object(m) => m
    _ => Map::new()
  }
  result_map["env"] = Json::object(env_map)
  Json::object(result_map)
}

///|
pub impl Agent for ClaudeCode with apply_provider(_self, provider) -> Unit raise Error {
  let config_path = get_claude_code_config_path()
  let dir_path = get_claude_code_dir_path()

  // Create directory if needed
  if !@fs.path_exists(dir_path) {
    let result = try? @fs.create_dir(dir_path)
    guard result is Ok(_) else { raise result.unwrap_err() }
  }

  // Load existing config or create new one
  let settings_json = if @fs.path_exists(config_path) {
    let read_result = try? @fs.read_file_to_string(config_path)
    guard read_result is Ok(content) else { raise read_result.unwrap_err() }
    let json_result = try? @json.parse(content)
    guard json_result is Ok(json) else { raise json_result.unwrap_err() }
    json
  } else {
    Json::object(Map::new())
  }

  // Apply provider settings in memory
  let updated_json = apply_provider_to_json(settings_json, provider)

  // Write back to file
  let content = updated_json.stringify(indent=2)
  let write_result = try? @fs.write_string_to_file(config_path, content)
  guard write_result is Ok(_) else { raise write_result.unwrap_err() }
}

///|
pub impl Agent for ClaudeCode with name(_) -> String {
  "Claude Code"
}
