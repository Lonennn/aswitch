///|
priv struct ResolvedTemporarySelection {
  agent : &@agent.Agent
  provider : @provider.Provider
}

///|
priv struct RenderedTemporaryCommand {
  command : String
  temporary_override : @agent.TemporaryOverride
}

///|
fn resolve_temporary_selection(
  agent_name : String,
  provider_name : String,
) -> Result[ResolvedTemporarySelection, Int] {
  let agent_result = @agent.create(agent_name)
  guard agent_result is Some(agent) else {
    println("Error: Unknown agent '\{agent_name}'")
    return Err(EXIT_CODE_UNKNOWN_AGENT)
  }

  let config = @core.load_config() catch {
    err => {
      println("Error: Failed to load config file, \{err}")
      return Err(EXIT_CODE_CONFIG_ERROR)
    }
  }

  let validate_result = @core.validate_config(config)
  guard validate_result is Ok(_) else {
    println(
      "Error: Invalid configuration - \{@core.validation_error_message(validate_result.unwrap_err())}",
    )
    return Err(EXIT_CODE_CONFIG_ERROR)
  }

  let provider_result = config.get_provider(provider_name)
  guard provider_result is Some(provider) else {
    println("Error: Unknown provider '\{provider_name}'")
    return Err(EXIT_CODE_UNKNOWN_PROVIDER)
  }

  Ok(ResolvedTemporarySelection::{ agent, provider })
}

///|
fn render_temporary_command(
  agent_name : String,
  provider_name : String,
  api_format : @agent.ApiFormat?,
  extra_args? : Array[String] = [],
) -> Result[RenderedTemporaryCommand, Int] {
  let selection_result = resolve_temporary_selection(agent_name, provider_name)
  guard selection_result is Ok(selection) else {
    return Err(selection_result.unwrap_err())
  }

  let temporary_override = selection.agent.get_temporary_override(
    selection.provider,
    api_format,
  ) catch {
    err => {
      println(
        "Error: Failed to render temporary override for provider '\{selection.provider.name}' and agent '\{selection.agent.name()}', \{err}",
      )
      return Err(EXIT_CODE_CONFIG_ERROR)
    }
  }

  Ok(RenderedTemporaryCommand::{
    command: @agent.render_posix_shell_command(temporary_override, extra_args~),
    temporary_override,
  })
}

///|
fn prepare_temporary_override(
  temporary_override : @agent.TemporaryOverride,
  agent_display_name : String,
) -> Result[Unit, Int] {
  @agent.prepare_temporary_override(temporary_override) catch {
    err => {
      println(
        "Error: Failed to prepare temporary override for agent '\{agent_display_name}', \{err}",
      )
      return Err(EXIT_CODE_CONFIG_ERROR)
    }
  }
  Ok(())
}

///|
fn resolve_provider_name(name : String) -> Result[String, Int] {
  let config = @core.load_config() catch {
    err => {
      println("Error: Failed to load config file, \{err}")
      return Err(EXIT_CODE_CONFIG_ERROR)
    }
  }
  match config.resolve_provider(name) {
    Ok(provider) => {
      if provider.name.to_lower() != name.to_lower() {
        println("Resolved provider '\{name}' to '\{provider.name}'")
      }
      Ok(provider.name)
    }
    Err(err) => {
      println("Error: \{err}")
      Err(EXIT_CODE_UNKNOWN_PROVIDER)
    }
  }
}

///|
/// This function is async because it may render the command inside a
/// temporary terminal buffer (@terminal.display_in_temporary_terminal_buffer)
/// to prevent secrets from leaking into terminal scrollback.
pub async fn temporary_command(
  agent_name : String?,
  provider_name : String?,
  api_format : @agent.ApiFormat?,
) -> Int {
  let state = @core.load_usage_state()

  let resolved_agent_name = resolve_agent_from_state(agent_name, state)
  guard resolved_agent_name is Ok(agent) else {
    return resolved_agent_name.unwrap_err()
  }

  let (resolved_provider_name, resolved_api_format) = match provider_name {
    Some(name) =>
      match resolve_provider_name(name) {
        Ok(provider_name) => (provider_name, api_format)
        Err(code) => return code
      }
    None =>
      match state.get_agent_state(agent) {
        Some(agent_state) =>
          (
            agent_state.provider,
            resolve_api_format_from_state(agent, api_format, state),
          )
        None => {
          println("Error: No previous provider found for agent '\{agent}'")
          println(
            "Usage: aswitch command [agent] [provider] [--api-format <fmt>]",
          )
          return EXIT_CODE_CONFIG_ERROR
        }
      }
  }

  let selection_result = resolve_temporary_selection(
    agent, resolved_provider_name,
  )
  guard selection_result is Ok(selection) else {
    return selection_result.unwrap_err()
  }
  if !selection.agent.supports_render_only() {
    println(
      "Error: 'command' does not support agent '\{selection.agent.name()}'; use 'exec' instead",
    )
    return EXIT_CODE_CONFIG_ERROR
  }

  let command_result = render_temporary_command(
    agent, resolved_provider_name, resolved_api_format,
  )
  guard command_result is Ok(rendered_command) else {
    return command_result.unwrap_err()
  }
  @terminal.display_in_temporary_terminal_buffer(rendered_command.command)

  // Save state on success (consistent with temporary_exec)
  let api_format_str = match resolved_api_format {
    Some(@agent.OpenAI) => Some("openai")
    Some(@agent.Anthropic) => Some("anthropic")
    None => None
  }
  state.set_agent_state(
    selection.agent.name(),
    selection.provider.name,
    api_format_str,
  )
  let save_result = @core.save_usage_state(state)
  if save_result is Err(err) {
    println("Warning: Failed to save usage state: \{err}")
  }

  EXIT_CODE_SUCCESS
}

///|
#borrow(executable, args)
extern "c" fn launch_command_ffi(
  executable : Bytes,
  args : FixedArray[Bytes],
) -> Int = "aswitch_launch_command"

///|
fn string_to_utf8_bytes(str : String, append_nul : Bool) -> Bytes {
  let bytes = @utf8.encode(str)
  if !append_nul {
    return bytes
  }
  let buf = Buffer::Buffer(size_hint=bytes.length() + 1)
  buf.write_bytes(bytes)
  buf.write_byte((0).to_byte())
  buf.to_bytes()
}

///|
fn apply_env_vars(env_vars : Array[@agent.EnvVar]) -> Unit {
  for env_var in env_vars {
    @sys.set_env_var(env_var.key, env_var.value)
  }
}

///|
fn build_args(
  override_args : Array[String],
  extra_args : Array[String],
) -> FixedArray[Bytes] {
  let total = override_args.length() + extra_args.length()
  let result = FixedArray::make(total, Bytes::new(0))
  for i in 0..<override_args.length() {
    result[i] = string_to_utf8_bytes(override_args[i], true)
  }
  for i in 0..<extra_args.length() {
    result[override_args.length() + i] = string_to_utf8_bytes(
      extra_args[i],
      true,
    )
  }
  result
}

///|
/// This function is async because it may render the command inside a
/// temporary terminal buffer
/// (@terminal.display_in_temporary_terminal_buffer) when --print-command is
/// used, to prevent secrets from leaking into terminal scrollback.
pub async fn temporary_exec(
  agent_name : String?,
  provider_name : String?,
  api_format : @agent.ApiFormat?,
  command : Array[String],
  print_command : Bool,
) -> Int {
  let state = @core.load_usage_state()

  let resolved_agent_name = resolve_agent_from_state(agent_name, state)
  guard resolved_agent_name is Ok(agent) else {
    return resolved_agent_name.unwrap_err()
  }

  let (resolved_provider_name, resolved_api_format) = match provider_name {
    Some(name) =>
      match resolve_provider_name(name) {
        Ok(provider_name) => (provider_name, api_format)
        Err(code) => return code
      }
    None =>
      match state.get_agent_state(agent) {
        Some(agent_state) =>
          (
            agent_state.provider,
            resolve_api_format_from_state(agent, api_format, state),
          )
        None => {
          println("Error: No previous provider found for agent '\{agent}'")
          println("Usage: aswitch run [agent] [provider] [-- <command...>]")
          return EXIT_CODE_CONFIG_ERROR
        }
      }
  }

  let selection_result = resolve_temporary_selection(
    agent, resolved_provider_name,
  )
  guard selection_result is Ok(selection) else {
    return selection_result.unwrap_err()
  }

  let command_result = render_temporary_command(
    agent,
    resolved_provider_name,
    resolved_api_format,
    extra_args=command,
  )
  guard command_result is Ok(rendered_command) else {
    return command_result.unwrap_err()
  }

  let prepare_result = prepare_temporary_override(
    rendered_command.temporary_override,
    selection.agent.name(),
  )
  guard prepare_result is Ok(_) else { return prepare_result.unwrap_err() }

  if print_command {
    @terminal.display_in_temporary_terminal_buffer(rendered_command.command)
  }

  // Save state on success BEFORE exec (exec replaces process and never returns)
  let api_format_str = match resolved_api_format {
    Some(@agent.OpenAI) => Some("openai")
    Some(@agent.Anthropic) => Some("anthropic")
    None => None
  }
  state.set_agent_state(
    selection.agent.name(),
    selection.provider.name,
    api_format_str,
  )
  let save_result = @core.save_usage_state(state)
  if save_result is Err(err) {
    println("Warning: Failed to save usage state: \{err}")
  }

  // execvp does not accept a custom environment — it inherits the current
  // process's environment. Set the agent's env vars now so the launched
  // process sees them.
  let temp_override = rendered_command.temporary_override
  apply_env_vars(temp_override.env_vars)

  // Launch the command. On Unix this replaces the current process via execvp;
  // on Windows it spawns and waits, then exits with the child's code. In both
  // cases success never returns to this point.
  let executable = string_to_utf8_bytes(temp_override.executable, true)
  let args = build_args(temp_override.args, command)
  let status = launch_command_ffi(executable, args)

  // Only reached if the launch failed.
  let error_reason = match status {
    -2 => "No such file or directory"
    -7 => "Argument list too long"
    -8 => "Exec format error"
    -12 => "Not enough memory"
    -13 => "Permission denied"
    -22 => "Invalid argument"
    _ => "launch failed (exit code: \{status})"
  }
  println("Error: '\{temp_override.executable}' - \{error_reason}")
  EXIT_CODE_CONFIG_ERROR
}

///|
fn resolve_agent_from_state(
  agent_name : String?,
  state : @core.UsageState,
) -> Result[String, Int] {
  match agent_name {
    Some(name) =>
      match @agent.resolve_agent_name(name) {
        Ok(resolved) => {
          if resolved.to_lower() != name.to_lower() {
            println("Resolved agent '\{name}' to '\{resolved}'")
          }
          Ok(resolved)
        }
        Err(err) => {
          println("Error: \{err}")
          Err(EXIT_CODE_UNKNOWN_AGENT)
        }
      }
    None =>
      match state.last_agent {
        Some(last) => Ok(last)
        None => {
          println("Error: No previous agent found. Please specify an agent.")
          println("Usage: aswitch run [agent] [provider] [-- <command...>]")
          Err(EXIT_CODE_CONFIG_ERROR)
        }
      }
  }
}
