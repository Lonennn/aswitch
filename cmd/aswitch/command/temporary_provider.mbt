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
fn cleanup_temporary_override(
  temporary_override : @agent.TemporaryOverride,
) -> Unit {
  for temp_file in temporary_override.temp_files {
    let _ = try? @fs.remove_file(temp_file.path)
    let parent_dir = @path.Path(temp_file.path).dirname().to_string()
    let _ = try? @fs.remove_dir(parent_dir)
  }
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
#borrow(command)
extern "c" fn run_shell_command(command : Bytes) -> Int = "system"

///|
fn string_to_utf8_bytes(str : String, append_nul : Bool) -> Bytes {
  let res : Array[Byte] = []
  let len = str.length()
  let mut i = 0
  while i < len {
    let mut c = str.code_unit_at(i).to_int()
    if 0xD800 <= c && c <= 0xDBFF {
      c -= 0xD800
      i = i + 1
      let l = str.code_unit_at(i).to_int() - 0xDC00
      c = (c << 10) + l + 0x10000
    }
    if c < 0x80 {
      res.push(c.to_byte())
    } else if c < 0x800 {
      res.push((0xc0 + (c >> 6)).to_byte())
      res.push((0x80 + (c & 0x3f)).to_byte())
    } else if c < 0x10000 {
      res.push((0xe0 + (c >> 12)).to_byte())
      res.push((0x80 + ((c >> 6) & 0x3f)).to_byte())
      res.push((0x80 + (c & 0x3f)).to_byte())
    } else {
      res.push((0xf0 + (c >> 18)).to_byte())
      res.push((0x80 + ((c >> 12) & 0x3f)).to_byte())
      res.push((0x80 + ((c >> 6) & 0x3f)).to_byte())
      res.push((0x80 + (c & 0x3f)).to_byte())
    }
    i += 1
  }
  if append_nul {
    res.push((0).to_byte())
  }
  Bytes::from_array(res)
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
  defer cleanup_temporary_override(rendered_command.temporary_override)

  if print_command {
    println(rendered_command.command)
  }
  // A leading space helps shells configured with ignorespace avoid saving
  // this secret-bearing command line into interactive history.
  let shell_command = " \{rendered_command.command}"
  let status = run_shell_command(string_to_utf8_bytes(shell_command, true))
  status
}
