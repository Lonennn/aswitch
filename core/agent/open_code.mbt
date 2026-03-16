///|
/// OpenCode agent implementation that manages ~/.config/opencode/opencode.json

///|
pub struct OpenCode {}

///|
const AI_SDK_OPENAI = "@ai-sdk/openai-compatible"

///|
const AI_SDK_ANTHROPIC = "@ai-sdk/anthropic"

///|
/// Get the OpenCode configuration file path (~/.config/opencode/opencode.json)
fn OpenCode::get_config_file_path() -> String {
  OpenCode::get_config_dir() + "/opencode.json"
}

///|
/// Get the OpenCode directory path (~/.config/opencode)
/// Supports Unix/macOS (XDG_CONFIG_HOME or HOME) and Windows (APPDATA)
fn OpenCode::get_config_dir() -> String {
  // Try XDG_CONFIG_HOME first (Unix standard)
  match @sys.get_env_var("XDG_CONFIG_HOME") {
    Some(config_home) => config_home + "/opencode"
    None => @util.get_user_home() + "/.config/opencode"
  }
}

///|
/// Get the base URL for a provider based on the API format
/// Returns the appropriate base URL or raises ProviderLackUrlError if none available
fn OpenCode::get_base_url(
  provider : @provider.Provider,
  api_format : ApiFormat?,
) -> String raise ProviderLackUrlError {
  match api_format {
    Some(OpenAI) =>
      provider.openai_base_url.unwrap_or_error(
        ProviderLackUrlError(
          "openai_base_url is required in your aswitch.json when you choose to use OpenAI compatible API",
        ),
      )
    Some(Anthropic) =>
      provider.anthropic_base_url.unwrap_or_error(
        ProviderLackUrlError(
          "anthropic_base_url is required in your aswitch.json when you choose to use Anthropic compatible API",
        ),
      )
    None =>
      match provider.anthropic_base_url {
        Some(url) => url
        None =>
          provider.openai_base_url.unwrap_or_error(
            ProviderLackUrlError(
              "anthropic_base_url or openai_base_url is required for OpenCode agent",
            ),
          )
      }
  }
}

///|
/// Create a model entry from a Model object, excluding null fields
fn OpenCode::create_model_entry(model : @provider.Model) -> Json {
  let entries = Map::new()
  entries["name"] = Json::string(model.name)

  // Only add optional fields if they are set
  match model.context_limit {
    Some(limit) => entries["context_limit"] = Json::number(limit.to_double())
    _ => ()
  }
  match model.output_limit {
    Some(limit) => entries["output_limit"] = Json::number(limit.to_double())
    _ => ()
  }

  // Only add modalities if they differ from default [Text]
  let is_default_text_modality = fn(arr : Array[@provider.Modality]) -> Bool {
    arr.length() == 1 && arr[0] == @provider.Modality::Text
  }
  let input_is_default = is_default_text_modality(model.input_modality)
  let output_is_default = is_default_text_modality(model.output_modality)

  if not(input_is_default) || not(output_is_default) {
    let modalities_map = Map::new()
    if not(input_is_default) {
      let input_strs = model.input_modality.map(fn(m) {
        match m {
          @provider.Modality::Text => "text"
          @provider.Modality::Vision => "vision"
          @provider.Modality::Audio => "audio"
        }
      })
      modalities_map["input"] = Json::array(
        input_strs.map(fn(s) { Json::string(s) }),
      )
    }
    if not(output_is_default) {
      let output_strs = model.output_modality.map(fn(m) {
        match m {
          @provider.Modality::Text => "text"
          @provider.Modality::Vision => "vision"
          @provider.Modality::Audio => "audio"
        }
      })
      modalities_map["output"] = Json::array(
        output_strs.map(fn(s) { Json::string(s) }),
      )
    }
    entries["modalities"] = Json::object(modalities_map)
  }

  Json::object(entries)
}

///|
/// Apply provider settings to a Json object in memory
/// This function modifies the "provider" object within the opencode JSON
/// while preserving all other properties
fn OpenCode::apply_provider_to_json(
  settings_json : Json,
  provider : @provider.Provider,
  api_format : ApiFormat?,
) -> Json raise Error {
  // Get or create the provider object
  let provider_json = match settings_json {
    { "provider": provider_obj, .. } => provider_obj
    _ => Json::object(Map::new())
  }

  // Convert provider to Map for modification
  let provider_map : Map[String, Json] = match provider_json {
    Json::Object(m) => m
    _ => Map::new()
  }

  // Get or create the specific provider entry
  let provider_key = provider.name
  let provider_entry = match provider_map.get(provider_key) {
    Some(entry) =>
      match entry {
        Json::Object(m) => m
        _ => Map::new()
      }
    _ => Map::new()
  }

  // Set npm package (using Open AI SDK by default)
  provider_entry["npm"] = Json::string(
    match api_format {
      None => AI_SDK_OPENAI
      Some(format) =>
        match format {
          OpenAI => AI_SDK_OPENAI
          Anthropic => AI_SDK_ANTHROPIC
        }
    },
  )

  // Set display name
  provider_entry["name"] = Json::string(provider.name)

  // Get or create the options object
  let options_map = match provider_entry.get("options") {
    Some(options) =>
      match options {
        Json::Object(m) => m
        _ => Map::new()
      }
    _ => Map::new()
  }

  // Set API key
  options_map["apiKey"] = Json::string(provider.api_key)

  // Set base URL
  let base_url = OpenCode::get_base_url(provider, api_format)
  options_map["baseURL"] = Json::string(base_url)
  provider_entry["options"] = Json::object(options_map)

  // Set models - at least one model is required
  let model_count = provider.models.length()
  if model_count == 0 {
    raise ProviderLackUrlError(
      "at least one model is required for OpenCode agent",
    )
  }

  // Get or create the models object
  let models_map = match provider_entry.get("models") {
    Some(models) =>
      match models {
        Json::Object(m) => m
        _ => Map::new()
      }
    _ => Map::new()
  }

  // Add each model from the provider
  for model in provider.models {
    let model_name = model.name
    models_map[model_name] = OpenCode::create_model_entry(model)
  }
  provider_entry["models"] = Json::object(models_map)

  // Update the provider map with the new/updated entry
  provider_map[provider_key] = Json::object(provider_entry)

  // Build the result JSON, preserving other properties
  let result_map : Map[String, Json] = match settings_json {
    Json::Object(m) => m
    _ => Map::new()
  }
  result_map["provider"] = Json::object(provider_map)

  // Add schema if not present
  if not(result_map.contains("$schema")) {
    result_map["$schema"] = Json::string("https://opencode.ai/config.json")
  }
  Json::object(result_map)
}

///|
pub impl Agent for OpenCode with apply_provider(_self, provider, api_format) -> Unit raise Error {
  let config_path = OpenCode::get_config_file_path()
  let dir_path = OpenCode::get_config_dir()

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
  let updated_json = OpenCode::apply_provider_to_json(
    settings_json, provider, api_format,
  )

  // Write back to file
  let content = updated_json.stringify(indent=2)
  let write_result = try? @fs.write_string_to_file(config_path, content)
  guard write_result is Ok(_) else { raise write_result.unwrap_err() }
}

///|
pub impl Agent for OpenCode with name(_) -> String {
  "OpenCode"
}
