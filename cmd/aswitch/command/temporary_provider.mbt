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

  let load_config_result = try? @core.load_config()
  guard load_config_result is Ok(config) else {
    println(
      "Error: Failed to load config file, \{load_config_result.unwrap_err()}",
    )
    return Err(EXIT_CODE_CONFIG_ERROR)
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
fn command_supports_render_only(agent : &@agent.Agent) -> Bool {
  agent.name() != "OpenClaw"
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

  let override_result = try? selection.agent.get_temporary_override(
    selection.provider,
    api_format,
  )
  guard override_result is Ok(temporary_override) else {
    println(
      "Error: Failed to render temporary override for provider '\{selection.provider.name}' and agent '\{selection.agent.name()}', \{override_result.unwrap_err()}",
    )
    return Err(EXIT_CODE_CONFIG_ERROR)
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
  let prepare_result = try? @agent.prepare_temporary_override(
    temporary_override,
  )
  guard prepare_result is Ok(_) else {
    println(
      "Error: Failed to prepare temporary override for agent '\{agent_display_name}', \{prepare_result.unwrap_err()}",
    )
    return Err(EXIT_CODE_CONFIG_ERROR)
  }
  Ok(())
}

///|
pub fn temporary_command(
  agent_name : String,
  provider_name : String,
  api_format : @agent.ApiFormat?,
) -> Int {
  let selection_result = resolve_temporary_selection(agent_name, provider_name)
  guard selection_result is Ok(selection) else {
    return selection_result.unwrap_err()
  }
  if !command_supports_render_only(selection.agent) {
    println(
      "Error: 'command' does not support agent '\{selection.agent.name()}'; use 'exec' instead",
    )
    return EXIT_CODE_CONFIG_ERROR
  }

  let command_result = render_temporary_command(
    agent_name, provider_name, api_format,
  )
  guard command_result is Ok(rendered_command) else {
    return command_result.unwrap_err()
  }
  println(rendered_command.command)
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
  let buf = @buffer.new(size_hint=bytes.length() + 1)
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
pub fn temporary_exec(
  agent_name : String,
  provider_name : String,
  api_format : @agent.ApiFormat?,
  command : Array[String],
  print_command : Bool,
) -> Int {
  let selection_result = resolve_temporary_selection(agent_name, provider_name)
  guard selection_result is Ok(selection) else {
    return selection_result.unwrap_err()
  }

  let command_result = render_temporary_command(
    agent_name,
    provider_name,
    api_format,
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
    println(rendered_command.command)
  }

  // execvp does not accept a custom environment — it inherits the current
  // process's environment. Set the agent's env vars now so the launched
  // process sees them.
  let temp_override = rendered_command.temporary_override
  apply_env_vars(temp_override.env_vars)

  // Launch the command by replacing the current process.
  // On success this never returns; the TUI agent takes over the terminal.
  let executable = string_to_utf8_bytes(temp_override.executable, true)
  let args = build_args(temp_override.args, command)
  let status = launch_command_ffi(executable, args)

  // Only reached if the exec failed (executable not found, etc.).
  println(
    "Error: Failed to launch '\{temp_override.executable}' (exit code: \{status})",
  )
  EXIT_CODE_CONFIG_ERROR
}
