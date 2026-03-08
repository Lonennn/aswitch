///|
/// Switch provider for an agent

///|
/// Switch an agent to a different provider
pub fn switch_provider(agent_name : String, provider : String) -> Int {
  // Validate agent name
  let agent_result = @agent.create(agent_name)
  guard agent_result is Some(_agent) else { EXIT_CODE_UNKNOWN_AGENT }

  let load_config_result = try? @core.load_config()
  guard load_config_result is Ok(config) else { EXIT_CODE_CONFIG_ERROR }

  // Check if provider exists
  if !config.has_provider(provider) {
    println("Error: Provider '\{provider}' not found")
    return EXIT_CODE_UNKNOWN_PROVIDER
  }

  // Save the config (which now has the new active provider)
  match @core.save_config(config) {
    Ok(_) => {
      println("Switched agent '\{agent_name}' to provider '\{provider}'")
      EXIT_CODE_SUCCESS
    }
    Err(e) => {
      println("Error: \{e}")
      EXIT_CODE_CONFIG_ERROR
    }
  }
}
