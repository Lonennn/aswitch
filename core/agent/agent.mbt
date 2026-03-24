///|
/// API format type for agents that support multiple API formats
pub(all) enum ApiFormat {
  OpenAI
  Anthropic
}

///|
pub(open) trait Agent {
  name(Self) -> String
  apply_provider(Self, @provider.Provider, ApiFormat?) -> Unit raise Error
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
pub suberror ProviderLackUrlError {
  ProviderLackUrlError(String)
}

impl Show for ProviderLackUrlError with output(self, logger) -> Unit {
  match self {
    ProviderLackUrlError(msg) => logger.write_string("ProviderLackUrlError: \{msg}")
  }
}
