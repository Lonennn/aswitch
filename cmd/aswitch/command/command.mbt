///|
/// Available CLI commands
pub enum Command {
  /// Initialize configuration
  Init
  /// List all providers
  ListProviders
  /// List supported agents
  ListAgents
  /// Set active provider (optional api_format: "openai" or "anthropic")
  SetProvider(
    agent~ : String,
    provider~ : String,
    api_format~ : @agent.ApiFormat?,
    dry_run~ : Bool
  )
  /// Render a shell command for a temporary provider override
  TemporaryCommand(
    agent~ : String,
    provider~ : String,
    api_format~ : @agent.ApiFormat?
  )
  /// Execute a command with a temporary provider override
  TemporaryExec(
    agent~ : String,
    provider~ : String,
    api_format~ : @agent.ApiFormat?,
    command~ : Array[String],
    print_command~ : Bool
  )
  /// Show help
  Help
  /// Show version
  Version
  /// Add a provider in interactive mode
  AddProviderInteractive
  /// Add or update a provider from command line arguments
  AddProvider(
    name~ : String,
    api_key~ : String,
    model~ : String,
    openai_base_url~ : String?,
    anthropic_base_url~ : String?
  )
  /// Remove a provider by name
  RemoveProvider(String)
  /// Unknown command
  Unknown(String)
  /// Some parameters error
  ErrorParameter(String)
} derive(Debug)

///|
/// Parse set/switch command arguments and extract dry-run flag
fn parse_set_command(args : Array[String]) -> Command {
  let mut dry_run = false
  let filtered_args : Array[String] = []
  for arg in args {
    if arg == "--dry-run" || arg == "-n" {
      dry_run = true
    } else {
      filtered_args.push(arg)
    }
  }
  match filtered_args {
    [agent, provider, .. rest] =>
      if rest.length() == 0 {
        Command::SetProvider(agent~, provider~, api_format=None, dry_run~)
      } else {
        let api_format = match rest[0].to_lower() {
          "openai" => @agent.OpenAI
          "anthropic" => @agent.Anthropic
          _ =>
            return Command::ErrorParameter(
              "Unknown API format \{rest[0]}, the selectable values are 'openai' and 'anthropic'",
            )
        }
        Command::SetProvider(
          agent~,
          provider~,
          api_format=Some(api_format),
          dry_run~,
        )
      }
    [_] => {
      println("Error: 'set' requires at least 2 arguments: <agent> <provider>")
      Command::Help
    }
    [] => {
      println("Error: 'set' requires at least 2 arguments: <agent> <provider>")
      Command::Help
    }
  }
}

///|
fn parse_add_flags(args : Array[String]) -> Command {
  let mut name : String? = None
  let mut api_key : String? = None
  let mut model : String? = None
  let mut openai_base_url : String? = None
  let mut anthropic_base_url : String? = None
  let mut i = 0
  while i < args.length() {
    let arg = args[i]
    let next_value = fn() -> String? {
      if i + 1 >= args.length() {
        None
      } else {
        Some(args[i + 1])
      }
    }
    match arg {
      "--name" =>
        match next_value() {
          Some(value) => {
            name = Some(value)
            i += 2
          }
          None =>
            return Command::ErrorParameter("Error: '--name' requires a value")
        }
      "--api-key" =>
        match next_value() {
          Some(value) => {
            api_key = Some(value)
            i += 2
          }
          None =>
            return Command::ErrorParameter(
              "Error: '--api-key' requires a value",
            )
        }
      "--model" =>
        match next_value() {
          Some(value) => {
            model = Some(value)
            i += 2
          }
          None =>
            return Command::ErrorParameter("Error: '--model' requires a value")
        }
      "--openai-base-url" =>
        match next_value() {
          Some(value) => {
            openai_base_url = Some(value)
            i += 2
          }
          None =>
            return Command::ErrorParameter(
              "Error: '--openai-base-url' requires a value",
            )
        }
      "--anthropic-base-url" =>
        match next_value() {
          Some(value) => {
            anthropic_base_url = Some(value)
            i += 2
          }
          None =>
            return Command::ErrorParameter(
              "Error: '--anthropic-base-url' requires a value",
            )
        }
      _ =>
        return Command::ErrorParameter(
          "Error: unknown add option '\{arg}'. Supported options: --name --api-key --model --openai-base-url --anthropic-base-url",
        )
    }
  }

  guard name is Some(provider_name) else {
    return Command::ErrorParameter(
      "Error: add option mode requires --name --api-key --model and at least one base URL (--openai-base-url or --anthropic-base-url)",
    )
  }
  guard api_key is Some(provider_api_key) else {
    return Command::ErrorParameter(
      "Error: add option mode requires --name --api-key --model and at least one base URL (--openai-base-url or --anthropic-base-url)",
    )
  }
  guard model is Some(provider_model) else {
    return Command::ErrorParameter(
      "Error: add option mode requires --name --api-key --model and at least one base URL (--openai-base-url or --anthropic-base-url)",
    )
  }
  if openai_base_url is None && anthropic_base_url is None {
    return Command::ErrorParameter(
      "Error: add option mode requires at least one base URL (--openai-base-url or --anthropic-base-url)",
    )
  }

  Command::AddProvider(
    name=provider_name,
    api_key=provider_api_key,
    model=provider_model,
    openai_base_url~,
    anthropic_base_url~,
  )
}

///|
fn parse_add_command(args : Array[String]) -> Command {
  match args {
    [] => Command::AddProviderInteractive
    [name, api_key, base_url, model] if !name.has_prefix("--") =>
      Command::AddProvider(
        name~,
        api_key~,
        model~,
        openai_base_url=Some(base_url),
        anthropic_base_url=None,
      )
    _ => parse_add_flags(args)
  }
}

///|
fn parse_api_format_flag(
  args : Array[String],
) -> Result[(Array[String], @agent.ApiFormat?), String] {
  let mut api_format : @agent.ApiFormat? = None
  let filtered_args : Array[String] = []
  let mut i = 0
  while i < args.length() {
    let arg = args[i]
    if arg == "--api-format" {
      if i + 1 >= args.length() {
        return Err("Error: '--api-format' requires a value")
      }
      api_format = match args[i + 1].to_lower() {
        "openai" => Some(@agent.OpenAI)
        "anthropic" => Some(@agent.Anthropic)
        _ =>
          return Err(
            "Error: unknown API format '\{args[i + 1]}'. Supported values: openai, anthropic",
          )
      }
      i += 2
    } else {
      filtered_args.push(arg)
      i += 1
    }
  }
  Ok((filtered_args, api_format))
}

///|
fn parse_temporary_command(args : Array[String]) -> Command {
  let parse_result = parse_api_format_flag(args)
  guard parse_result is Ok((filtered_args, api_format)) else {
    return Command::ErrorParameter(parse_result.unwrap_err())
  }
  match filtered_args {
    [agent, provider] =>
      Command::TemporaryCommand(agent~, provider~, api_format~)
    _ =>
      Command::ErrorParameter(
        "Error: 'command' requires <agent> <provider> and optional --api-format <openai|anthropic>",
      )
  }
}

///|
fn parse_temporary_exec(args : Array[String]) -> Command {
  let mut separator_index : Int? = None
  for i in 0..<args.length() {
    if args[i] == "--" {
      separator_index = Some(i)
      break
    }
  }
  let prefix : Array[String] = []
  let command : Array[String] = []
  match separator_index {
    Some(index) => {
      for i in 0..<index {
        prefix.push(args[i])
      }
      for i in (index + 1)..<args.length() {
        command.push(args[i])
      }
      if command.is_empty() {
        return Command::ErrorParameter(
          "Error: 'exec' requires at least one command argument after '--'",
        )
      }
    }
    None =>
      for arg in args {
        prefix.push(arg)
      }
  }

  let api_format_result = parse_api_format_flag(prefix)
  guard api_format_result is Ok((prefix_without_format, api_format)) else {
    return Command::ErrorParameter(api_format_result.unwrap_err())
  }

  let mut print_command = false
  let filtered_args : Array[String] = []
  let mut i = 0
  while i < prefix_without_format.length() {
    let arg = prefix_without_format[i]
    if arg == "--print-command" {
      print_command = true
      i += 1
    } else {
      filtered_args.push(arg)
      i += 1
    }
  }
  match filtered_args {
    [agent, provider] =>
      Command::TemporaryExec(
        agent~,
        provider~,
        api_format~,
        command~,
        print_command~,
      )
    _ =>
      Command::ErrorParameter(
        "Error: 'exec' requires <agent> <provider> and optional --api-format <openai|anthropic> or --print-command before '--'",
      )
  }
}

///|
/// Parse command line arguments into a Command
pub fn parse_args(args : Array[String]) -> Command {
  match args {
    [] => Command::Help
    ["add", .. rest] => parse_add_command(rest.to_array())
    ["providers" | "list" | "ls"] => Command::ListProviders
    ["agents"] => Command::ListAgents
    ["command", .. rest] => parse_temporary_command(rest.to_array())
    ["exec", .. rest] => parse_temporary_exec(rest.to_array())
    ["set" | "switch", .. args] => parse_set_command(args.to_array())
    ["remove" | "rm", name, ..] => Command::RemoveProvider(name)
    ["remove" | "rm"] => {
      println("Error: 'remove' requires provider name")
      Command::Help
    }
    ["export"] => {
      println("Error: 'export' requires agent name (e.g. claude-code)")
      Command::Help
    }
    ["help" | "-h" | "--help"] => Command::Help
    ["version" | "-v" | "--version"] => Command::Version
    ["init"] => Command::Init
    // ["add", name, api_key, base_url, model] => {
    //   Command::AddProvider(name, api_key, base_url, model)
    // }
    [cmd, ..] => Command::Unknown(cmd)
  }
}
