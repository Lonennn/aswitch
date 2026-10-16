///|
/// Print usage information
pub fn print_help() -> Int32 {
  println("aswitch - AI Model Provider Configuration Manager")
  println("")
  println("Usage: aswitch <command> [arguments]")
  println("")
  println("Commands:")
  println("  init                        Initialize configuration file")
  println("  providers                   List all configured providers")
  println("  agents                      List all supported agents")
  println(
    "  set <agent> [provider] [api_format]               Set to a different provider",
  )
  println(
    "                                                      (provider from state if omitted)",
  )
  println("  command [agent] [provider] [--api-format <fmt>] [--raw] [--copy]")
  println(
    "                                                      Show a temporary shell command",
  )
  println(
    "                                                      (args from state if omitted; --copy takes precedence over --raw)",
  )
  println(
    "  run [agent] [provider] [--api-format <fmt>] [--print-command] [-- <command...>]",
  )
  println(
    "                                                      Run with temporary provider override",
  )
  println(
    "                                                      (args from state if omitted)",
  )
  println(
    "  add                         Add or update a provider (interactive)",
  )
  println("  add <name> <api_key> <base_url> <model>")
  println(
    "      Stores the API key in the OS keychain when available; falls back to legacy inline config when unavailable.",
  )
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
  println("  aswitch command claude-code seed")
  println("  aswitch command claude-code seed --raw")
  println("  aswitch command claude-code seed --copy")
  println("  aswitch run open-code seed -- opencode run")
  println("  aswitch run open-code seed --print-command -- opencode run")
  println("  aswitch run claude-code seed -- claude")
  println("  aswitch add")
  println("  aswitch add openai sk-xxx https://api.openai.com/v1 gpt-4")
  println(
    "  aswitch add --name anthropic --api-key sk-xxx --model claude-3-7-sonnet --anthropic-base-url https://api.anthropic.com",
  )
  println("  aswitch remove openai")
  // println("  aswitch export claude-code")
  0
}
