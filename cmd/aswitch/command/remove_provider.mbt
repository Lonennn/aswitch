///|
/// Remove a provider from configuration by name
pub async fn remove_provider(name : String) -> Int {
  let result = run_remove_provider(name, read_stdin_line, println)
  match result {
    (EXIT_CODE_SUCCESS, message) => {
      println(message)
      EXIT_CODE_SUCCESS
    }
    (EXIT_CODE_UNKNOWN_PROVIDER, message) => {
      println(message)
      EXIT_CODE_UNKNOWN_PROVIDER
    }
    (_, message) => {
      println(message)
      EXIT_CODE_CONFIG_ERROR
    }
  }
}

///|
async fn run_remove_provider(
  name : String,
  read_line : async () -> String?,
  write_line : (String) -> Unit,
) -> (Int, String) {
  let provider_name = name.trim().to_string()
  if provider_name.is_empty() {
    return (EXIT_CODE_CONFIG_ERROR, "Error: provider name cannot be empty")
  }

  let load_result = try? @core.load_config()
  guard load_result is Ok(config) else {
    return (
      EXIT_CODE_CONFIG_ERROR,
      "Error: Failed to load config file, \{load_result.unwrap_err()}",
    )
  }

  guard config.get_provider(provider_name) is Some(existing_provider) else {
    return (
      EXIT_CODE_UNKNOWN_PROVIDER,
      "Error: Unknown provider '\{provider_name}'",
    )
  }

  let confirm_prompt = "Remove provider '\{existing_provider.name}'? (y/N):"
  let confirm_result = prompt_yes_no(confirm_prompt, read_line, write_line)
  guard confirm_result is Some(confirmed) else {
    return (
      EXIT_CODE_CONFIG_ERROR,
      "Error: Input aborted while confirming provider removal",
    )
  }
  if !confirmed {
    return (EXIT_CODE_CONFIG_ERROR, "Operation canceled")
  }

  let remove_name_lower = existing_provider.name.to_lower()
  let updated_providers = @list.from_array(
    config.providers
    .to_array()
    .filter(fn(provider) { provider.name.to_lower() != remove_name_lower }),
  )
  let updated_config = config.deep_copy()
  updated_config.providers = updated_providers
  let validate_result = @core.validate_config(updated_config)
  guard validate_result is Ok(_) else {
    return (
      EXIT_CODE_CONFIG_ERROR,
      "Error: Invalid configuration after remove operation",
    )
  }

  let config_path = @core.get_config_path()
  let backup_result = try? @agent.backup_config_before_write(config_path)
  guard backup_result is Ok(_) else {
    return (
      EXIT_CODE_CONFIG_ERROR,
      "Error: Failed to backup config file: \{backup_result.unwrap_err()}",
    )
  }

  let save_result = @core.save_providers_preserving_other_fields(
    config_path, updated_providers,
  )
  guard save_result is Ok(_) else {
    return (EXIT_CODE_CONFIG_ERROR, "Error: \{save_result.unwrap_err()}")
  }

  (EXIT_CODE_SUCCESS, "Removed provider '\{existing_provider.name}'")
}
