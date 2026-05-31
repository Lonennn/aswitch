///|
/// Set provider for an agent

///|
/// Set an agent to use a different provider
/// api_format is optional and only used by some agents (e.g., OpenCode)
pub fn set_provider(
  agent_name : String,
  provider_name : String?,
  api_format : @agent.ApiFormat?,
  dry_run : Bool,
) -> Int {
  let config_path = @core.get_config_path()
  println("Loading configuration from: \{config_path}")

  let load_config_result = try? @core.load_config()
  guard load_config_result is Ok(config) else {
    println(
      "Error: Failed to load config file, \{load_config_result.unwrap_err()}",
    )
    return EXIT_CODE_CONFIG_ERROR
  }

  // Resolve agent name to canonical form
  let canonical_agent = match @agent.resolve_agent_name(agent_name) {
    Ok(agent) => {
      if agent.to_lower() != agent_name.to_lower() {
        println("Resolved agent '\{agent_name}' to '\{agent}'")
      }
      agent
    }
    Err(err) => {
      println("Error: \{err}")
      return EXIT_CODE_UNKNOWN_AGENT
    }
  }

  // Resolve provider and api_format from state if needed
  let state = @core.load_usage_state()

  let provider = match provider_name {
    Some(name) =>
      match config.resolve_provider(name) {
        Ok(p) => {
          if p.name.to_lower() != name.to_lower() {
            println("Resolved provider '\{name}' to '\{p.name}'")
          }
          p
        }
        Err(err) => {
          println("Error: \{err}")
          return EXIT_CODE_UNKNOWN_PROVIDER
        }
      }
    None =>
      match state.get_agent_state(canonical_agent) {
        Some(agent_state) =>
          match config.get_provider(agent_state.provider) {
            Some(p) => p
            None => {
              println(
                "Error: Provider '\{agent_state.provider}' from state no longer exists in config",
              )
              print_help() |> ignore
              return EXIT_CODE_CONFIG_ERROR
            }
          }
        None => {
          println(
            "Error: No previous provider found for agent '\{canonical_agent}'",
          )
          print_help() |> ignore
          return EXIT_CODE_CONFIG_ERROR
        }
      }
  }

  let resolved_api_format = resolve_api_format_from_state(
    canonical_agent, api_format, state,
  )

  let agent = match @agent.create(canonical_agent) {
    Some(a) => a
    None => {
      println("Error: Unknown agent '\{canonical_agent}'")
      return EXIT_CODE_UNKNOWN_AGENT
    }
  }

  // Apply the provider to the agent (with optional api_format)
  if dry_run {
    // For dry run, we need to get the diff without writing
    let diff_result = try? agent.get_provider_diff(
      provider, resolved_api_format,
    )
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
    let apply_result = try? agent.apply_provider(provider, resolved_api_format)
    guard apply_result is Ok(_) else {
      let err = apply_result.unwrap_err()
      println(
        "Error: Failed to apply provider '\{provider.name}' to agent '\{agent.name()}', \{err}",
      )
      return EXIT_CODE_CONFIG_ERROR
    }
    println("Successfully set \{agent.name()} to use \{provider.name}")

    // Save state on success (not on dry-run)
    let api_format_str = match resolved_api_format {
      Some(@agent.OpenAI) => Some("openai")
      Some(@agent.Anthropic) => Some("anthropic")
      None => None
    }
    state.set_agent_state(agent.name(), provider.name, api_format_str)
    let save_result = @core.save_usage_state(state)
    if save_result is Err(err) {
      println("Warning: Failed to save usage state: \{err}")
    }

    EXIT_CODE_SUCCESS
  }
}

///|
fn resolve_api_format_from_state(
  agent_name : String,
  api_format : @agent.ApiFormat?,
  state : @core.UsageState,
) -> @agent.ApiFormat? {
  match api_format {
    Some(fmt) => Some(fmt)
    None =>
      match state.get_agent_state(agent_name) {
        Some(agent_state) =>
          match agent_state.api_format {
            Some("openai") => Some(@agent.OpenAI)
            Some("anthropic") => Some(@agent.Anthropic)
            _ => None
          }
        None => None
      }
  }
}
