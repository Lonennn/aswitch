///|
/// List all configured providers

///|
/// Print all configured providers
pub fn list_providers() -> Int {
  let load_config_result = try? @core.load_config()
  guard load_config_result is Ok(config) else {
    println(load_config_result.unwrap_err())
    EXIT_CODE_CONFIG_ERROR
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
