///|
/// Claude Code agent implementation that manages ~/.claude/settings.json

///|
pub struct ClaudeCode {}

///|
/// Get the Claude Code configuration file path (~/.claude/settings.json)
pub fn ClaudeCode::get_config_file_path() -> String {
  @path.Path::join(ClaudeCode::get_config_dir(), "settings.json").to_string()
}

///|
/// Get the Claude Code directory path (~/.claude)
/// Supports Unix/macOS (HOME) and Windows (USERPROFILE)
fn ClaudeCode::get_config_dir() -> String {
  let home = @util.get_user_home()
  if home == "." {
    ".claude"
  } else {
    @path.Path::join(home, ".claude").to_string()
  }
}

///|
/// Apply provider settings to a Json object in memory
/// This function modifies the "env" object within the settings JSON
/// while preserving all other properties
fn ClaudeCode::apply_provider_to_json(
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
  env_map["ANTHROPIC_DEFAULT_OPUS_MODEL"] = Json::string(
    provider.models[0].name,
  )
  if model_count > 1 {
    env_map["ANTHROPIC_DEFAULT_SONNET_MODEL"] = Json::string(
      provider.models[1].name,
    )
  } else {
    env_map["ANTHROPIC_DEFAULT_SONNET_MODEL"] = Json::string(
      provider.models[model_count - 1].name,
    )
  }
  if model_count > 2 {
    env_map["ANTHROPIC_DEFAULT_HAIKU_MODEL"] = Json::string(
      provider.models[2].name,
    )
  } else {
    env_map["ANTHROPIC_DEFAULT_HAIKU_MODEL"] = Json::string(
      provider.models[model_count - 1].name,
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
pub impl Agent for ClaudeCode with apply_provider(_, provider, _) -> Unit raise Error {
  let config_path = ClaudeCode::get_config_file_path()
  let dir_path = ClaudeCode::get_config_dir()

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
  let updated_json = ClaudeCode::apply_provider_to_json(settings_json, provider)

  // Write back to file
  let content = updated_json.stringify(indent=2)
  write_config_with_backup(config_path, content)
}

///|
/// Generate a diff of what changes would be made without writing to disk
fn ClaudeCode::get_provider_diff(
  _ : ClaudeCode,
  provider : @provider.Provider,
  _ : ApiFormat?,
) -> ProviderDiff raise Error {
  let config_path = ClaudeCode::get_config_file_path()
  generate_provider_diff(config_path, fn(settings) raise {
    ClaudeCode::apply_provider_to_json(settings, provider)
  })
}

///|
pub impl Agent for ClaudeCode with get_provider_diff(self, provider, api_format) -> ProviderDiff raise Error {
  ClaudeCode::get_provider_diff(self, provider, api_format)
}

///|
pub impl Agent for ClaudeCode with name(_ : ClaudeCode) -> String {
  "Claude Code"
}
