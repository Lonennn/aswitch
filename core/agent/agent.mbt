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
/// Agent metadata structure containing all information about supported agents
priv struct AgentMeta {
  canonical_name : String
  aliases : Array[String]
  get_config_path : () -> String
  create_instance : () -> &Agent
}

///|
/// Single source of truth for all supported agents
let agent_meta : Array[AgentMeta] = [
  AgentMeta::{
    canonical_name: "claude-code",
    aliases: ["claude", "claudecode"],
    get_config_path: () => ClaudeCode::get_config_file_path(),
    create_instance: () => ClaudeCode::{  },
  },
  AgentMeta::{
    canonical_name: "open-code",
    aliases: ["opencode"],
    get_config_path: () => OpenCode::get_config_file_path(),
    create_instance: () => OpenCode::{  },
  },
  AgentMeta::{
    canonical_name: "openclaw",
    aliases: ["open-claw"],
    get_config_path: () => OpenClaw::get_config_file_path(),
    create_instance: () => OpenClaw::{  },
  },
]

///|
/// Helper to find agent metadata by name (supports aliases)
fn find_agent_meta(agent_name : String) -> AgentMeta? {
  let name_lower = agent_name.to_lower()
  for meta in agent_meta {
    if meta.canonical_name == name_lower || meta.aliases.contains(name_lower) {
      return Some(meta)
    }
  }
  None
}

///|
pub fn create(agent_name : String) -> &Agent? {
  match find_agent_meta(agent_name) {
    Some(meta) => Some((meta.create_instance)())
    None => None
  }
}

///|
pub fn supported_agents() -> Array[String] {
  let result = []
  for meta in agent_meta {
    result.push(meta.canonical_name)
  }
  result
}

///|
/// Get the configuration file path for a given agent
/// Returns None if the agent is not supported
pub fn get_agent_config_path(agent_name : String) -> String? {
  match find_agent_meta(agent_name) {
    Some(meta) => Some((meta.get_config_path)())
    None => None
  }
}

///|
/// Check if an agent is installed (config file exists at standard path)
/// Returns false if the agent is not supported or config file does not exist
pub fn is_agent_installed(agent_name : String) -> Bool {
  match get_agent_config_path(agent_name) {
    Some(path) => @fs.path_exists(path)
    None => false
  }
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
