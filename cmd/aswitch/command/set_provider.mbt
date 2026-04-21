///|
/// Set provider for an agent

///|
/// Set an agent to use a different provider
/// api_format is optional and only used by some agents (e.g., OpenCode)
pub fn set_provider(
  agent_name : String,
  provider_name : String,
  api_format : @agent.ApiFormat?,
  dry_run : Bool,
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

  // Validate configuration
  let validate_result = @core.validate_config(config)
  guard validate_result is Ok(_) else {
    let err_msg = match validate_result.unwrap_err() {
      @core.ValidationError::EmptyProviderName =>
        "Provider name cannot be empty"
      @core.ValidationError::EmptyApiKey => "Provider API key cannot be empty"
      @core.ValidationError::NoBaseUrls =>
        "Provider must have at least one base URL configured"
      @core.ValidationError::InvalidBaseUrl(url) => "Invalid base URL: \{url}"
      @core.ValidationError::NoModels =>
        "Provider must have at least one model configured"
      @core.ValidationError::DuplicateProviderName(name) =>
        "Duplicate provider name: \{name}"
      @core.ValidationError::EmptyModelName => "Model name cannot be empty"
      @core.ValidationError::InvalidContextWindow(value) =>
        "Invalid context window size: \{value}"
    }
    println("Error: Invalid configuration - \{err_msg}")
    return EXIT_CODE_CONFIG_ERROR
  }

  // Get the provider by name
  let provider_result = config.get_provider(provider_name)
  guard provider_result is Some(provider) else {
    println("Error: Unknown provider '\{provider_name}'")
    EXIT_CODE_UNKNOWN_PROVIDER
  }

  // Apply the provider to the agent (with optional api_format)
  if dry_run {
    // For dry run, we need to get the diff without writing
    let diff_result = try? agent.get_provider_diff(provider, api_format)
    guard diff_result is Ok(diff) else {
      let err = diff_result.unwrap_err()
      println(
        "Error: Failed to generate diff for provider '\{provider.name}' to agent '\{agent.name()}', \{err}",
      )
      return EXIT_CODE_CONFIG_ERROR
    }

    println("Dry run mode enabled - no changes will be written to disk")
    println("=".repeat(60))
    println("Agent: \{agent.name()}")
    println("Provider: \{provider.name}")
    println("Config file: \{diff.config_path}")
    println("=".repeat(60))
    println("Changes that would be applied:")
    println(diff.diff_output)
    println("=".repeat(60))
    println("Dry run completed successfully - no changes were made")

    EXIT_CODE_SUCCESS
  } else {
    // Normal flow - apply and write changes
    let apply_result = try? agent.apply_provider(provider, api_format)
    guard apply_result is Ok(_) else {
      let err = apply_result.unwrap_err()
      println(
        "Error: Failed to apply provider '\{provider.name}' to agent '\{agent.name()}', \{err}",
      )
      return EXIT_CODE_CONFIG_ERROR
    }
    println("Successfully set \{agent.name()} to use \{provider.name}")
    EXIT_CODE_SUCCESS
  }
}
