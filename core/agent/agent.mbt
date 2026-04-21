///|
/// API format type for agents that support multiple API formats
pub(all) enum ApiFormat {
  OpenAI
  Anthropic
} derive(Eq, Debug)

///|
/// Struct to hold provider diff information for dry-run mode
pub struct ProviderDiff {
  config_path : String
  diff_output : String
}

///|
pub(open) trait Agent {
  name(Self) -> String
  apply_provider(Self, @provider.Provider, ApiFormat?) -> Unit raise Error
  get_provider_diff(Self, @provider.Provider, ApiFormat?) -> ProviderDiff raise Error
}

///|
/// Shared helper to generate provider diff for any agent type
/// Eliminates duplicate code across agent implementations
fn generate_provider_diff(
  config_path : String,
  apply_fn : (Json) -> Json raise Error,
) -> ProviderDiff raise Error {
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
  let updated_json = apply_fn(settings_json)

  // Generate diff
  let original_str = settings_json.stringify(indent=2)
  let updated_str = updated_json.stringify(indent=2)
  let diff_output = @util.generate_json_diff(original_str, updated_str)

  ProviderDiff::{ config_path, diff_output }
}

///|
pub fn create(agent_name : String) -> &Agent? {
  match agent_name.to_lower() {
    "claude" | "claudecode" => Some(ClaudeCode::{  })
    "opencode" | "open-code" => Some(OpenCode::{  })
    "openclaw" | "open-claw" => Some(OpenClaw::{  })
    _ => None
  }
}

///|
pub fn supported_agents() -> Array[String] {
  ["claude-code", "open-code", "openclaw"]
}

///|
pub suberror ProviderLackUrlError {
  ProviderLackUrlError(String)
}

///|
impl Show for ProviderLackUrlError with output(self, logger) -> Unit {
  match self {
    ProviderLackUrlError(msg) =>
      logger.write_string("ProviderLackUrlError: \{msg}")
  }
}
