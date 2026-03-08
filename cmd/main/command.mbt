///|
/// Available CLI commands
pub enum Command {
  /// Initialize configuration
  Init
  /// List all providers
  ListProviders
  /// Switch active provider
  SwitchProvider(agent~ : String, provider~ : String)
  /// Show help
  Help
  /// Show version
  Version
  /// Unknown command
  Unknown(String)
  /// Add a new provider
  // AddProvider(String, String, String, String)
  /// Remove a provider
  // RemoveProvider(String)
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
    ["list" | "ls"] => Command::ListProviders
    ["switch", agent, provider] => Command::SwitchProvider(agent~, provider~)
    ["switch", _] => {
      println("Error: 'switch' requires 2 arguments: <agent> <provider>")
      Command::Help
    }
    ["switch"] => {
      println("Error: 'switch' requires 2 arguments: <agent> <provider>")
      Command::Help
    }
    ["remove" | "rm"] => {
      println("Error: 'remove' requires provider name")
      Command::Help
    }
    ["export"] => {
      println("Error: 'export' requires agent name (e.g., claude-code)")
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
