///|
pub(open) trait Agent {
  apply_provider(Self, @provider.Provider) -> Unit raise Error
}

///|
pub fn create(agent_name : String) -> &Agent? {
  match agent_name.to_lower() {
    "claude" | "claudecode" => Some(ClaudeCode::{  })
    _ => None
  }
}
