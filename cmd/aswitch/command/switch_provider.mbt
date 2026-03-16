///|
/// Switch provider for an agent

///|
/// Switch an agent to a different provider
/// api_format is optional and only used by some agents (e.g., OpenCode)
pub fn switch_provider(
  agent_name : String,
  provider_name : String,
  api_format : @agent.ApiFormat?,
) -> Int {
  // Validate agent name
  let agent_result = @agent.create(agent_name)
  guard agent_result is Some(agent) else {
    println("Error: Unknown agent '\{agent_name}'")
    EXIT_CODE_UNKNOWN_AGENT
  }

  // Load configuration
  let config_path = @core.get_config_path()
  println("Loading configuration from: \{config_path}")
  let load_config_result = try? @core.load_config()
  guard load_config_result is Ok(config) else {
    println(
      "Error: Failed to load config file, \{load_config_result.unwrap_err()}",
    )
    EXIT_CODE_CONFIG_ERROR
  }

  // Get the provider by name
  let provider_result = config.get_provider(provider_name)
  guard provider_result is Some(provider) else {
    println("Error: Unknown provider '\{provider_name}'")
    EXIT_CODE_UNKNOWN_PROVIDER
  }

  // Apply the provider to the agent (with optional api_format)
  let apply_result = try? agent.apply_provider(provider, api_format)
  guard apply_result is Ok(_) else {
    let err = apply_result.unwrap_err()
    println(
      "Error: Failed to apply provider '\{provider.name}' to agent '\{agent.name()}', \{err}",
    )
    EXIT_CODE_CONFIG_ERROR
  }
  println("Successfully switch \{agent.name()} to use \{provider.name}")
  EXIT_CODE_SUCCESS
}
