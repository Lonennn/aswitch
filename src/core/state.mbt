///|
/// State for a single agent's last-used provider and API format
pub(all) struct AgentState {
  provider : String
  api_format : String?
} derive(ToJson, FromJson)

///|
/// Global usage state tracking last agent and per-agent states
pub(all) struct UsageState {
  mut last_agent : String?
  agent_states : Map[String, AgentState]
} derive(ToJson, FromJson)

///|
/// Default file name for usage state
pub const STATE_FILE_NAME : String = "state.json"

///|
/// Get the full path to the usage state file
pub fn get_state_path() -> String {
  @path.Path::join(@util.get_aswitch_home(), STATE_FILE_NAME).to_string()
}

///|
/// Create an empty usage state
pub fn UsageState::new() -> UsageState {
  { last_agent: None, agent_states: {} }
}

///|
/// Load usage state from file. Returns empty state if file does not exist.
pub fn load_usage_state() -> UsageState {
  let path = get_state_path()
  if !@fs.path_exists(path) {
    return UsageState::new()
  }
  let content = @fs.read_file_to_string(path) catch {
    err => {
      println("Failed to read file '\{path}', \{err}, ignore the state")
      return UsageState::new()
    }
  }
  let json = @json.parse(content) catch {
    err => {
      println("Failed to parse the file '\{path}', \{err}, ignore the state")
      return UsageState::new()
    }
  }
  @json.from_json(json) catch {
    err => {
      println("Failed to convert state json \{path}, \{err}, ignore the state")
      UsageState::new()
    }
  }
}

///|
/// Save usage state to file
pub fn save_usage_state(state : UsageState) -> Result[Unit, String] {
  let path = get_state_path()
  let parent_dir = @path.Path(path).dirname().to_string()
  @util.create_dirs(parent_dir) catch {
    err => return Err("Failed to create directory: \{err}")
  }
  let content = state.to_json().stringify(indent=2)
  try @fs.write_string_to_file(path, content) catch {
    err => Err("Failed to write state file: \{err}")
  } noraise {
    _ => Ok(())
  }
}

///|
/// Get the stored state for a specific agent (by canonical name)
pub fn UsageState::get_agent_state(
  self : UsageState,
  agent : String,
) -> AgentState? {
  self.agent_states.get(agent)
}

///|
/// Update or insert state for an agent and set it as last_agent
pub fn UsageState::set_agent_state(
  self : UsageState,
  agent : String,
  provider : String,
  api_format : String?,
) -> Unit {
  self.last_agent = Some(agent)
  self.agent_states.set(agent, { provider, api_format })
}
