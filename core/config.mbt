///|
/// Configuration file management module

// suberror ConfigError { 
//   ConfigError(Error)
// }

///|
/// Main configuration containing all providers and the active provider
pub(all) struct Config {
  /// list of providers
  providers : @list.List[@provider.Provider]
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
/// Default configuration file name
pub const CONFIG_FILE_NAME : String = "aswitch.json"

///|
/// Get the default configuration file path
/// Uses ASWITCH_HOME env var if set, otherwise uses home directory via HOME/USERPROFILE env vars
pub fn get_config_path() -> String {
  // Check for custom config directory via environment variable
  match @sys.get_env_var("ASWITCH_HOME") {
    Some(custom_home) => {
      let trimmed = custom_home.trim()
      if trimmed.is_empty() {
        CONFIG_FILE_NAME
      } else {
        @path.Path::join(trimmed.to_string(), CONFIG_FILE_NAME).to_string()
      }
    }
    None =>
      // Try HOME (Unix/macOS) or USERPROFILE (Windows)
      match @sys.get_env_var("HOME") {
        Some(home) => @path.Path::join(home, CONFIG_FILE_NAME).to_string()
        None =>
          match @sys.get_env_var("USERPROFILE") {
            Some(home) => @path.Path::join(home, CONFIG_FILE_NAME).to_string()
            None => CONFIG_FILE_NAME
          }
      }
  }
}

///|
/// Load configuration from file
pub fn load_config() -> Config raise Error {
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
