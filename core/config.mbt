///|
/// Configuration file management module

// suberror ConfigError { 
//   ConfigError(Error)
// }

///|
/// Main configuration containing all providers and the active provider
pub(all) struct Config {
  /// list of providers
  mut providers : @list.List[@provider.Provider]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn Config::new() -> Config {
  { providers: @list.new() }
}

///|
/// Check if the providers list is empty
pub fn Config::is_empty(self : Config) -> Bool {
  self.providers.is_empty()
}

///|
/// Check if a provider with the given name exists
pub fn Config::has_provider(self : Config, name : String) -> Bool {
  self.providers.any(fn(p) { p.name == name })
}

///|
/// Get a provider by name, returns None if not found
/// First tries case-sensitive match, then case-insensitive match
pub fn Config::get_provider(
  self : Config,
  name : String,
) -> @provider.Provider? {
  // Try case-sensitive match first
  match self.providers.find(fn(p) { p.name == name }) {
    Some(provider) => Some(provider)
    None => {
      // Fall back to case-insensitive match
      let name_lower = name.to_lower()
      self.providers.find(fn(p) { p.name.to_lower() == name_lower })
    }
  }
}

///|
pub fn Config::deep_copy(self : Config) -> Config {
  let providers = self.providers
    .to_array()
    .map(fn(provider) { provider.deep_copy() })
  Config::{ providers: @list.from_array(providers) }
}

///|
/// Default configuration file name
pub const CONFIG_FILE_NAME : String = "aswitch.json"

///|
/// Get the default configuration file path
/// Uses ASWITCH_HOME env var if set, otherwise uses home directory via HOME/USERPROFILE env vars
pub fn get_config_path() -> String {
  // Check for custom config directory via environment variable
  guard @sys.get_env_var("ASWITCH_HOME") is Some(custom_home) else {
    return @path.Path::join(@util.get_user_home(), CONFIG_FILE_NAME).to_string()
  }
  let trimmed = custom_home.trim()
  if trimmed.is_empty() {
    CONFIG_FILE_NAME
  } else {
    @path.Path::join(trimmed.to_string(), CONFIG_FILE_NAME).to_string()
  }
}

///|
/// Load configuration from file
pub fn load_config(validate? : Bool = true) -> Config raise Error {
  let path = get_config_path()
  if !@fs.path_exists(path) {
    return Config::new()
  }
  let read_file_result = try? @fs.read_file_to_string(path)
  guard read_file_result is Ok(file_content) else {
    raise read_file_result.unwrap_err()
  }
  let parse_json_result = try? @json.parse(file_content)
  guard parse_json_result is Ok(json) else {
    raise parse_json_result.unwrap_err()
  }
  let config_result : Result[Config, _] = try? @json.from_json(json)
  guard config_result is Ok(config) else { raise config_result.unwrap_err() }

  // Validate config if requested (enabled by default)
  if validate {
    let validate_result = validate_config(config)
    guard validate_result is Ok(_) else {
      let err_msg = match validate_result.unwrap_err() {
        ValidationError::EmptyProviderName => "Provider name cannot be empty"
        ValidationError::EmptyApiKey => "Provider API key cannot be empty"
        ValidationError::NoBaseUrls =>
          "Provider must have at least one base URL configured"
        ValidationError::InvalidBaseUrl(url) => "Invalid base URL: \{url}"
        ValidationError::NoModels =>
          "Provider must have at least one model configured"
        ValidationError::DuplicateProviderName(name) =>
          "Duplicate provider name: \{name}"
        ValidationError::EmptyModelName => "Model name cannot be empty"
        ValidationError::InvalidContextWindow(value) =>
          "Invalid context window size: \{value}"
      }
      raise @fs.IOError::IOError("Invalid configuration: \{err_msg}")
    }
  }

  config
}

///|
/// Save configuration to file
pub fn save_config(config : Config) -> Result[Unit, String] {
  let path = get_config_path()
  let content = config.to_json().stringify(indent=4)
  let write_result = try? @fs.write_string_to_file(path, content)
  match write_result {
    Ok(_) => Ok(())
    Err(e) => Err("Failed to write config file: \{e}")
  }
}

///|
/// Save providers while preserving other top-level fields in existing aswitch.json.
pub fn save_providers_preserving_other_fields(
  config_path : String,
  providers : @list.List[@provider.Provider],
) -> Result[Unit, String] {
  let mut config_json = Json::object({})
  if @fs.path_exists(config_path) {
    let read_result = try? @fs.read_file_to_string(config_path)
    guard read_result is Ok(content) else {
      return Err(
        "Failed to read existing config file: \{read_result.unwrap_err()}",
      )
    }
    let parse_result = try? @json.parse(content)
    guard parse_result is Ok(parsed) else {
      return Err(
        "Failed to parse existing config file: \{parse_result.unwrap_err()}",
      )
    }
    config_json = parsed
  }

  match config_json {
    Json::Object(entries) => {
      entries["providers"] = providers.to_json()
      let content = Json::object(entries).stringify(indent=4)
      let write_result = try? @fs.write_string_to_file(config_path, content)
      guard write_result is Ok(_) else {
        return Err("Failed to write config file: \{write_result.unwrap_err()}")
      }
      Ok(())
    }
    _ =>
      Err(
        "Failed to write config file: existing config root must be a JSON object",
      )
  }
}
