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
/// Resolve a provider by exact match or unique prefix match.
/// Returns the provider, or an error if ambiguous or unknown.
pub fn Config::resolve_provider(
  self : Config,
  name : String,
) -> Result[@provider.Provider, String] {
  // Try exact match first
  match self.get_provider(name) {
    Some(provider) => Ok(provider)
    None => {
      if name.length() < @agent.MIN_PREFIX_LENGTH {
        return Err(
          "Provider name too short: '\{name}' (minimum \{@agent.MIN_PREFIX_LENGTH} characters)",
        )
      }
      let prefix = name.to_lower()
      let matches : Array[@provider.Provider] = []
      for provider in self.providers {
        if provider.name.to_lower().has_prefix(prefix) {
          matches.push(provider)
        }
      }
      match matches {
        [provider] => Ok(provider)
        [] => Err("Unknown provider '\{name}'")
        _ => {
          let candidates = matches.map(fn(p) { "'\{p.name}'" }).join(", ")
          Err("Ambiguous provider '\{name}': matches \{candidates}")
        }
      }
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
  @path.Path::join(@util.get_aswitch_home(), CONFIG_FILE_NAME).to_string()
}

///|
/// Load configuration from file
pub fn load_config(validate? : Bool = true) -> Config raise Error {
  let path = get_config_path()
  if !@fs.path_exists(path) {
    return Config::new()
  }
  let file_content = @fs.read_file_to_string(path)
  let json = @json.parse(file_content)
  let config : Config = @json.from_json(json)

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
  try @fs.write_string_to_file(path, content) catch {
    err => Err("Failed to write config file: \{err}")
  } noraise {
    _ => Ok(())
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
    let content = @fs.read_file_to_string(config_path) catch {
      err => return Err("Failed to read existing config file: \{err}")
    }
    config_json = @json.parse(content) catch {
      err => return Err("Failed to parse existing config file: \{err}")
    }
  }

  match config_json {
    Json::Object(entries) => {
      entries["providers"] = providers.to_json()
      let content = Json::object(entries).stringify(indent=4)
      @fs.write_string_to_file(config_path, content) catch {
        err => return Err("Failed to write config file: \{err}")
      }
      Ok(())
    }
    _ =>
      Err(
        "Failed to write config file: existing config root must be a JSON object",
      )
  }
}
