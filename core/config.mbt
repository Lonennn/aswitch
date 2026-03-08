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
} derive(Show, Eq, ToJson, FromJson)

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
/// Default configuration file name
pub const CONFIG_FILE_NAME : String = "aswitch.json"

///|
/// Get the default configuration file path
/// Uses aswitch_HOME env var if set, otherwise uses current directory
pub fn get_config_path() -> String {
  // Check for custom config directory via environment variable
  match @sys.get_env_var("aswitch_HOME") {
    Some(custom_home) => {
      let trimmed = custom_home.trim()
      if trimmed.is_empty() {
        CONFIG_FILE_NAME
      } else {
        trimmed.to_string() + "/" + CONFIG_FILE_NAME
      }
    }
    None => CONFIG_FILE_NAME
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
  let content = config.to_json().to_string()

  let write_result = try? @fs.write_string_to_file(path, content)
  match write_result {
    Ok(_) => Ok(())
    Err(e) => Err("Failed to write config file: \{e}")
  }
}
