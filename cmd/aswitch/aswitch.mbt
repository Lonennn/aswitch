///|
/// Main entry point for the aswitch CLI tool
fn main {
  let args = @sys.get_cli_args()

  // Skip the program name (first argument)
  let cmd_args : Array[String] = match args {
    [_] => []
    [_, .. rest] => rest.to_array()
    [] => []
  }
  let command = @command.parse_args(cmd_args)
  @sys.exit(execute_command(command))
}

///|
fn execute_command(command : @command.Command) -> Int {
  match command {
    @command.Command::Init => @command.init_config()
    @command.Command::ListProviders => @command.list_providers()
    @command.Command::SwitchProvider(agent~, provider~, api_format~) =>
      @command.switch_provider(agent, provider, api_format)
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
  println("aswitch v0.1.0")
  0
}
