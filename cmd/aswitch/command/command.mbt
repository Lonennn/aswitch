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
  /// Show help
  Help
  /// Show version
  Version
  /// Unknown command
  Unknown(String)
  /// Some parameters error
  ErrorParameter(String)
  /// Add a new provider
  // AddProvider(String, String, String, String)
  /// Remove a provider
  // RemoveProvider(String)
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
/// Parse command line arguments into a Command
pub fn parse_args(args : Array[String]) -> Command {
  match args {
    [] => Command::Help
    ["add", .. rest] if rest.length() < 4 => {
      println(
        "Error: 'add' requires 4 arguments: <name> <api_key> <base_url> <model>",
      )
      Command::Help
    }
    ["providers" | "list" | "ls"] => Command::ListProviders
    ["agents"] => Command::ListAgents
    ["set" | "switch", .. args] => parse_set_command(args.to_array())
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
    // ["remove" | "rm", name] => Command::RemoveProvider(name)
    // ["add", name, api_key, base_url, model] => {
    //   Command::AddProvider(name, api_key, base_url, model)
    // }
    [cmd, ..] => Command::Unknown(cmd)
  }
}
