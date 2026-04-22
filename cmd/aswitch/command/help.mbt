///|
/// Print usage information
pub fn print_help() -> Int {
  println("aswitch - AI Model Provider Configuration Manager")
  println("")
  println("Usage: aswitch <command> [arguments]")
  println("")
  println("Commands:")
  println("  init                        Initialize configuration file")
  println("  providers                   List all configured providers")
  println("  agents                      List all supported agents")
  println(
    "  set <agent name> <provider_name>                  Set to a different provider",
  )
  println(
    "  add                         Add or update a provider (interactive)",
  )
  println("  add <name> <api_key> <base_url> <model>")
  println(
    "                              Quick add (OpenAI-compatible base URL)",
  )
  println(
    "  add --name <name> --api-key <key> --model <model> [--openai-base-url <url>] [--anthropic-base-url <url>]",
  )
  println(
    "                              Add provider with explicit API format URLs",
  )
  println("  remove, rm <name>           Remove a provider")
  // println("  current                     Show the current active provider")
  // println("  export <agent>              Export config for agent (claude-code)")
  println("  help, -h, --help            Show this help message")
  println("  version, -v, --version      Show version information")
  println("")
  println("Examples:")
  println("  aswitch init")
  println("  aswitch providers")
  println("  aswitch agents")
  println("  aswitch set claude glm")
  println("  aswitch add")
  println("  aswitch add openai sk-xxx https://api.openai.com/v1 gpt-4")
  println(
    "  aswitch add --name anthropic --api-key sk-xxx --model claude-3-7-sonnet --anthropic-base-url https://api.anthropic.com",
  )
  println("  aswitch remove openai")
  // println("  aswitch export claude-code")
  0
}
