///|
/// Available CLI commands
pub enum Command {
  /// Initialize configuration
  Init
  /// List all providers
  ListProviders
  /// Set active provider (optional api_format: "openai" or "anthropic")
  SetProvider(
    agent~ : String,
    provider~ : String,
    api_format~ : @agent.ApiFormat?
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
    ["set" | "switch", agent, provider, .. rest] =>
      if rest.length() == 0 {
        Command::SetProvider(agent~, provider~, api_format=None)
      } else {
        let api_format = match rest[0].to_lower() {
          "openai" => @agent.OpenAI
          "anthropic" => @agent.Anthropic
          _ =>
            return Command::ErrorParameter(
              "Unknown API format \{rest[0]}, the selectable values are 'openai' and 'anthropic'",
            )
        }
        Command::SetProvider(agent~, provider~, api_format=Some(api_format))
      }
    ["set" | "switch", _] => {
      println("Error: 'set' requires at least 2 arguments: <agent> <provider>")
      Command::Help
    }
    ["set" | "switch"] => {
      println("Error: 'set' requires at least 2 arguments: <agent> <provider>")
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
