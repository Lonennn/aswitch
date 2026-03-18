///|
/// Print usage information
pub fn print_help() -> Int {
  println("aswitch - AI Model Provider Configuration Manager")
  println("")
  println("Usage: aswitch <command> [arguments]")
  println("")
  println("Commands:")
  println("  init                        Initialize configuration file")
  println("  list, ls                    List all configured providers")
  println(
    "  set <agent name> <provider_name>                  Set to a different provider",
  )
  // println("  add <name> <api_key> <base_url> <model>")
  // println(
  //   "                              Add or update a provider configuration",
  // )
  // println("  remove, rm <name>           Remove a provider")
  // println("  current                     Show the current active provider")
  // println("  export <agent>              Export config for agent (claude-code)")
  println("  help, -h, --help            Show this help message")
  println("  version, -v, --version      Show version information")
  println("")
  println("Examples:")
  println("  aswitch init")
  println("  aswitch set claude glm")
  // println("  aswitch add openai sk-xxx https://api.openai.com/v1 gpt-4")
  // println(
  //   "  aswitch add anthropic sk-xxx https://api.anthropic.com claude-3-opus",
  // )
  // println("  aswitch export claude-code")
  0
}
