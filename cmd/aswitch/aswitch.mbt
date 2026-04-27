///|
/// Main entry point for the aswitch CLI tool
async fn main {
  let args = @sys.get_cli_args()

  // Skip the program name (first argument)
  let cmd_args : Array[String] = match args {
    [_] => []
    [_, .. rest] => rest.to_array()
    [] => []
  }
  let command = @command.parse_args(cmd_args)
  let exit_code = execute_command(command) catch {
    err => {
      println("Unhandled error: \{err}")
      1
    }
  }
  @sys.exit(exit_code)
}

///|
async fn execute_command(command : @command.Command) -> Int {
  match command {
    @command.Command::Init => @command.init_config()
    @command.Command::ListProviders => @command.list_providers()
    @command.Command::ListAgents => @command.list_agents()
    @command.Command::SetProvider(agent~, provider~, api_format~, dry_run~) =>
      @command.set_provider(agent, provider, api_format, dry_run)
    @command.Command::TemporaryCommand(agent~, provider~, api_format~) =>
      @command.temporary_command(agent, provider, api_format)
    @command.Command::TemporaryExec(
      agent~,
      provider~,
      api_format~,
      command~,
      print_command~
    ) =>
      @command.temporary_exec(
        agent, provider, api_format, command, print_command,
      )
    @command.Command::AddProviderInteractive =>
      @command.add_provider_interactive()
    @command.Command::AddProvider(
      name~,
      api_key~,
      model~,
      openai_base_url~,
      anthropic_base_url~
    ) =>
      @command.add_provider(
        name, api_key, model, openai_base_url, anthropic_base_url,
      )
    @command.Command::RemoveProvider(name) => @command.remove_provider(name)
    @command.Command::Help => @command.print_help()
    @command.Command::Version => print_version()
    @command.Command::Unknown(cmd) => {
      println("Unknown command: \{cmd}")
      println("Use 'aswitch help' for usage information")
      1
    }
    @command.Command::ErrorParameter(err) => {
      println(err)
      1
    }
  }
}

///|
/// Print version information
pub fn print_version() -> Int {
  println("aswitch v0.4.0")
  0
}
