///|
/// List all configured providers

///|
/// Print all configured providers
pub fn list_providers() -> Int {
  let config = @core.load_config() catch {
    err => {
      println(err)
      return EXIT_CODE_CONFIG_ERROR
    }
  }
  if config.providers.is_empty() {
    println("No providers configured")
  } else {
    println("Configured providers:")
    for provider in config.providers {
      println("    \{provider.name}")
    }
    println("\nTotal: \{config.providers.length()} provider(s)")
  }
  EXIT_CODE_SUCCESS
}
