///|
/// OpenClaw agent implementation that manages ~/.openclaw/openclaw.json

///|
pub struct OpenClaw {}

///|
const AI_API_OPENAI = "openai-completions"

///|
const AI_API_ANTHROPIC = "anthropic-messages"

///|
/// Get the OpenClaw configuration file path (~/.openclaw/openclaw.json)
pub fn OpenClaw::get_config_file_path() -> String {
  @path.Path::join(OpenClaw::get_config_dir(), "openclaw.json").to_string()
}

///|
/// Get the OpenClaw directory path (~/.openclaw)
/// Supports Unix/macOS (HOME) and Windows (USERPROFILE)
fn OpenClaw::get_config_dir() -> String {
  let home = @util.get_user_home()
  if home == "." {
    ".openclaw"
  } else {
    @path.Path::join(home, ".openclaw").to_string()
  }
}

///|
fn OpenClaw::get_temporary_override_dir() -> String {
  let base_dir = match @sys.get_env_var("ASWITCH_HOME") {
    Some(custom_home) => {
      let trimmed = custom_home.trim()
      if trimmed.is_empty() {
        "."
      } else {
        trimmed.to_string()
      }
    }
    None => @util.get_user_home()
  }
  @path.Path(base_dir).join(".aswitch-temp").to_string()
}

///|
fn OpenClaw::get_temporary_override_path(
  provider : @provider.Provider,
  api_format : ApiFormat?,
) -> String {
  let format_name = match api_format {
    Some(OpenAI) => "openai"
    Some(Anthropic) => "anthropic"
    None => "auto"
  }
  @path.Path(OpenClaw::get_temporary_override_dir())
  .join("openclaw-\{provider.name.to_lower()}-\{format_name}.json")
  .to_string()
}

///|
/// Determine both API type and base URL based on api_format and available base URLs
/// Returns (api_type, base_url) tuple or raises ProviderLackUrlError if ambiguous
fn OpenClaw::determine_api_config(
  provider : @provider.Provider,
  api_format : ApiFormat?,
) -> (String, String) raise ProviderLackUrlError {
  match api_format {
    Some(OpenAI) =>
      (
        AI_API_OPENAI,
        provider.openai_base_url.unwrap_or_error(
          ProviderLackUrlError(
            "openai_base_url is required in your aswitch.json when you choose to use OpenAI compatible API",
          ),
        ),
      )
    Some(Anthropic) =>
      (
        AI_API_ANTHROPIC,
        provider.anthropic_base_url.unwrap_or_error(
          ProviderLackUrlError(
            "anthropic_base_url is required in your aswitch.json when you choose to use Anthropic compatible API",
          ),
        ),
      )
    None =>
      match (provider.openai_base_url, provider.anthropic_base_url) {
        (None, Some(url)) => (AI_API_ANTHROPIC, url)
        (Some(url), _) => (AI_API_OPENAI, url)
        (None, None) =>
          raise ProviderLackUrlError(
            "anthropic_base_url or openai_base_url is required for OpenClaw agent",
          )
      }
  }
}

///|
/// Create a model entry from a Model object for OpenClaw configuration
fn OpenClaw::create_model_entry(model : @provider.Model) -> Json {
  let entries = Map::new()
  entries["id"] = Json::string(model.name)
  entries["name"] = Json::string(model.name)
  entries["reasoning"] = Json::boolean(false)

  // Set context window
  match model.context_limit {
    Some(limit) => entries["contextWindow"] = Json::number(limit.to_double())
    _ => entries["contextWindow"] = Json::number(16000.0)
  }

  // Set max tokens
  match model.output_limit {
    Some(limit) => entries["maxTokens"] = Json::number(limit.to_double())
    _ => entries["maxTokens"] = Json::number(4096.0)
  }

  // Set input modalities (default to text)
  let input_strs = model.input_modality.map(fn(m) {
    match m {
      @provider.Modality::Text => "text"
      @provider.Modality::Vision => "vision"
      @provider.Modality::Audio => "audio"
    }
  })
  entries["input"] = Json::array(input_strs.map(fn(s) { Json::string(s) }))

  // Set cost structure (all zeros as default)
  let cost_map = Map::new()
  cost_map["input"] = Json::number(0.0)
  cost_map["output"] = Json::number(0.0)
  cost_map["cacheRead"] = Json::number(0.0)
  cost_map["cacheWrite"] = Json::number(0.0)
  entries["cost"] = Json::object(cost_map)

  Json::object(entries)
}

///|
/// Apply provider settings to a Json object in memory
/// This function modifies the "models.providers" object within the openclaw JSON
/// while preserving all other properties
fn OpenClaw::apply_provider_to_json(
  settings_json : Json,
  provider : @provider.Provider,
  api_format : ApiFormat?,
) -> Json raise Error {
  // Get or create models object
  let models_json = match settings_json {
    { "models": models_obj, .. } => models_obj
    _ => Json::object(Map::new())
  }

  let models_map : Map[String, Json] = match models_json {
    Json::Object(m) => m
    _ => Map::new()
  }

  // Set mode to merge if not present
  if !models_map.contains("mode") {
    models_map["mode"] = Json::string("merge")
  }

  // Get or create providers object
  let providers_json = match models_map.get("providers") {
    Some(providers_obj) => providers_obj
    _ => Json::object(Map::new())
  }

  let providers_map : Map[String, Json] = match providers_json {
    Json::Object(m) => m
    _ => Map::new()
  }

  // Determine API config
  let (api_type, base_url) = OpenClaw::determine_api_config(
    provider, api_format,
  )

  // Create provider entry
  let provider_entry = Map::new()
  provider_entry["baseUrl"] = Json::string(base_url)
  provider_entry["apiKey"] = Json::string(provider.api_key)
  provider_entry["api"] = Json::string(api_type)

  // Add models
  let models_array = provider.models.map(fn(model) {
    OpenClaw::create_model_entry(model)
  })
  provider_entry["models"] = Json::array(models_array)

  // Update providers map
  providers_map[provider.name] = Json::object(provider_entry)
  models_map["providers"] = Json::object(providers_map)

  // Update agents.defaults.model.primary to use first model
  let agents_json = match settings_json {
    { "agents": agents_obj, .. } => agents_obj
    _ => Json::object(Map::new())
  }

  let agents_map : Map[String, Json] = match agents_json {
    Json::Object(m) => m
    _ => Map::new()
  }

  let defaults_json = match agents_map.get("defaults") {
    Some(defaults_obj) => defaults_obj
    _ => Json::object(Map::new())
  }

  let defaults_map : Map[String, Json] = match defaults_json {
    Json::Object(m) => m
    _ => Map::new()
  }

  let model_json = match defaults_map.get("model") {
    Some(model_obj) => model_obj
    _ => Json::object(Map::new())
  }

  let model_map : Map[String, Json] = match model_json {
    Json::Object(m) => m
    _ => Map::new()
  }

  // Set primary model to first model from provider
  let primary_model_id = if provider.models.length() > 0 {
    "\{provider.name}/\{provider.models[0].name}"
  } else {
    ""
  }

  if primary_model_id != "" {
    model_map["primary"] = Json::string(primary_model_id)
    defaults_map["model"] = Json::object(model_map)
    agents_map["defaults"] = Json::object(defaults_map)
  }

  // Build final result
  let result_map : Map[String, Json] = match settings_json {
    Json::Object(m) => m
    _ => Map::new()
  }

  result_map["models"] = Json::object(models_map)
  result_map["agents"] = Json::object(agents_map)

  Json::object(result_map)
}

///|
pub impl Agent for OpenClaw with apply_provider(_self, provider, api_format) -> Unit raise Error {
  let config_path = OpenClaw::get_config_file_path()
  let dir_path = OpenClaw::get_config_dir()

  // Create directory if needed
  if !@fs.path_exists(dir_path) {
    try! @fs.create_dir(dir_path)
  }

  // Load existing config or create new one
  let settings_json = if @fs.path_exists(config_path) {
    let read_result = try? @fs.read_file_to_string(config_path)
    guard read_result is Ok(content) else { raise read_result.unwrap_err() }
    let json_result = try? @json.parse(content)
    guard json_result is Ok(json) else { raise json_result.unwrap_err() }
    json
  } else {
    Json::object(Map::new())
  }

  // Apply provider settings in memory
  let updated_json = OpenClaw::apply_provider_to_json(
    settings_json, provider, api_format,
  )

  // Write back to file
  let content = updated_json.stringify(indent=2)
  write_config_with_backup(config_path, content)
}

///|
/// Generate a diff of what changes would be made without writing to disk
fn OpenClaw::get_provider_diff(
  _ : OpenClaw,
  provider : @provider.Provider,
  api_format : ApiFormat?,
) -> ProviderDiff raise Error {
  let config_path = OpenClaw::get_config_file_path()
  generate_provider_diff(config_path, fn(settings) raise {
    OpenClaw::apply_provider_to_json(settings, provider, api_format)
  })
}

///|
pub impl Agent for OpenClaw with get_provider_diff(self, provider, api_format) -> ProviderDiff raise Error {
  OpenClaw::get_provider_diff(self, provider, api_format)
}

///|
fn OpenClaw::get_temporary_override(
  _ : OpenClaw,
  provider : @provider.Provider,
  api_format : ApiFormat?,
) -> TemporaryOverride raise Error {
  let config_path = OpenClaw::get_config_file_path()
  let settings_json = load_agent_settings_json(config_path)
  let updated_json = OpenClaw::apply_provider_to_json(
    settings_json, provider, api_format,
  )
  let temp_path = OpenClaw::get_temporary_override_path(provider, api_format)
  TemporaryOverride::{
    executable: "openclaw",
    args: [],
    env_vars: [EnvVar::{ key: "OPENCLAW_CONFIG_PATH", value: temp_path }],
    temp_files: [
      TempFile::{ path: temp_path, content: updated_json.stringify(indent=2) },
    ],
  }
}

///|
pub impl Agent for OpenClaw with get_temporary_override(
  self,
  provider,
  api_format,
) -> TemporaryOverride raise Error {
  OpenClaw::get_temporary_override(self, provider, api_format)
}

///|
pub impl Agent for OpenClaw with name(_ : OpenClaw) -> String {
  "OpenClaw"
}
