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
  let config_path = @core.get_config_path()
  println("Loading configuration from: \{config_path}")

  let selection_result = resolve_temporary_selection(agent_name, provider_name)
  guard selection_result is Ok(selection) else {
    return selection_result.unwrap_err()
  }
  let agent = selection.agent
  let provider = selection.provider

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
