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
  let read_result = try? @fs.read_file_to_string(path)
  guard read_result is Ok(content) else {
    println(
      "Failed to read file '\{path}', \{read_result.unwrap_err()}, ignore the state",
    )
    return UsageState::new()
  }
  let parse_result = try? @json.parse(content)
  guard parse_result is Ok(json) else {
    println(
      "Failed to parse the file '\{path}', \{parse_result.unwrap_err()}, ignore the state",
    )
    return UsageState::new()
  }
  let state_result : Result[UsageState, _] = try? @json.from_json(json)
  guard state_result is Ok(state) else {
    println(
      "Failed to convert state json \{path}, \{state_result.unwrap_err()}, ignore the state",
    )
    return UsageState::new()
  }
  state
}

///|
/// Save usage state to file
pub fn save_usage_state(state : UsageState) -> Result[Unit, String] {
  let path = get_state_path()
  let parent_dir = @path.Path(path).dirname().to_string()
  let create_dir_result = try? @util.create_dirs(parent_dir)
  guard create_dir_result is Ok(_) else {
    return Err("Failed to create directory: \{create_dir_result.unwrap_err()}")
  }
  let content = state.to_json().stringify(indent=2)
  let write_result = try? @fs.write_string_to_file(path, content)
  match write_result {
    Ok(_) => Ok(())
    Err(e) => Err("Failed to write state file: \{e}")
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
