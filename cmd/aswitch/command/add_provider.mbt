///|
/// Add or update a provider using interactive prompts
pub async fn add_provider_interactive() -> Int {
  println("Interactive provider setup")
  println("Press Ctrl+D (EOF) to cancel")
  println("")
  let result = run_add_provider_interactive(read_stdin_line, println)
  match result {
    Ok(msg) => {
      println(msg)
      EXIT_CODE_SUCCESS
    }
    Err(err) => {
      println("Error: \{err}")
      EXIT_CODE_CONFIG_ERROR
    }
  }
}

///|
/// Add or update a provider from command line arguments
pub async fn add_provider(
  name : String,
  api_key : String,
  model : String,
  openai_base_url : String?,
  anthropic_base_url : String?,
) -> Int {
  let provider = @provider.Provider::{
    name,
    api_key,
    openai_base_url,
    anthropic_base_url,
    models: [@provider.Model::new(name=model)],
  }
  let result = upsert_provider(provider, read_stdin_line, println)
  match result {
    Ok(msg) => {
      println(msg)
      EXIT_CODE_SUCCESS
    }
    Err(err) => {
      println("Error: \{err}")
      EXIT_CODE_CONFIG_ERROR
    }
  }
}

///|
async fn run_add_provider_interactive(
  read_line : async () -> String?,
  write_line : (String) -> Unit,
) -> Result[String, String] {
  let provider_name = prompt_required(
    "Provider name (required):", read_line, write_line,
  )
  guard provider_name is Some(name) else {
    return Err("Input aborted while reading provider name")
  }

  let api_key = prompt_required("API key (required):", read_line, write_line)
  guard api_key is Some(key) else {
    return Err("Input aborted while reading API key")
  }

  let base_urls_result = prompt_base_urls(read_line, write_line)
  guard base_urls_result is Ok((openai_base_url, anthropic_base_url)) else {
    return Err(base_urls_result.unwrap_err())
  }

  let models_result = prompt_models(read_line, write_line)
  guard models_result is Ok(models) else {
    return Err(models_result.unwrap_err())
  }

  let provider = @provider.Provider::{
    name,
    api_key: key,
    openai_base_url,
    anthropic_base_url,
    models,
  }
  upsert_provider(provider, read_line, write_line)
}

///|
async fn prompt_base_urls(
  read_line : async () -> String?,
  write_line : (String) -> Unit,
) -> Result[(String?, String?), String] {
  let openai_base_url = prompt_optional(
    "OpenAI base URL (optional):", read_line, write_line,
  )
  guard openai_base_url is Some(openai) else {
    return Err("Input aborted while reading OpenAI base URL")
  }

  let anthropic_base_url = prompt_optional(
    "Anthropic base URL (optional):", read_line, write_line,
  )
  guard anthropic_base_url is Some(anthropic) else {
    return Err("Input aborted while reading Anthropic base URL")
  }

  if openai is None && anthropic is None {
    write_line("At least one base URL is required")
    prompt_base_urls(read_line, write_line)
  } else {
    Ok((openai, anthropic))
  }
}

///|
async fn prompt_models(
  read_line : async () -> String?,
  write_line : (String) -> Unit,
) -> Result[Array[@provider.Model], String] {
  let first_model_name = prompt_required(
    "Model name (required):", read_line, write_line,
  )
  guard first_model_name is Some(model_name) else {
    return Err("Input aborted while reading model name")
  }

  let models : Array[@provider.Model] = [@provider.Model::new(name=model_name)]
  collect_more_models(models, read_line, write_line)
}

///|
async fn collect_more_models(
  models : Array[@provider.Model],
  read_line : async () -> String?,
  write_line : (String) -> Unit,
) -> Result[Array[@provider.Model], String] {
  let should_continue = prompt_yes_no(
    "Add another model? (y/N):", read_line, write_line,
  )
  guard should_continue is Some(continue_flag) else {
    return Err("Input aborted while confirming model list")
  }

  if !continue_flag {
    return Ok(models)
  }

  let next_model_name = prompt_required(
    "Model name (required):", read_line, write_line,
  )
  guard next_model_name is Some(model_name) else {
    return Err("Input aborted while reading model name")
  }

  models.push(@provider.Model::new(name=model_name))
  collect_more_models(models, read_line, write_line)
}

///|
async fn prompt_required(
  prompt : String,
  read_line : async () -> String?,
  write_line : (String) -> Unit,
) -> String? {
  write_line(prompt)
  match read_line() {
    None => None
    Some(line) => {
      let value = line.trim().to_string()
      if value.is_empty() {
        write_line("This field is required. Please enter a non-empty value.")
        prompt_required(prompt, read_line, write_line)
      } else {
        Some(value)
      }
    }
  }
}

///|
async fn prompt_optional(
  prompt : String,
  read_line : async () -> String?,
  write_line : (String) -> Unit,
) -> String?? {
  write_line(prompt)
  match read_line() {
    None => None
    Some(line) => {
      let value = line.trim().to_string()
      if value.is_empty() {
        Some(None)
      } else {
        Some(Some(value))
      }
    }
  }
}

///|
async fn prompt_yes_no(
  prompt : String,
  read_line : async () -> String?,
  write_line : (String) -> Unit,
) -> Bool? {
  write_line(prompt)
  match read_line() {
    None => None
    Some(line) => {
      let normalized = line.trim().to_lower()
      if normalized.is_empty() {
        Some(false)
      } else if normalized == "y" || normalized == "yes" {
        Some(true)
      } else if normalized == "n" || normalized == "no" {
        Some(false)
      } else {
        write_line("Please answer with 'y' or 'n'.")
        prompt_yes_no(prompt, read_line, write_line)
      }
    }
  }
}

///|
async fn upsert_provider(
  provider : @provider.Provider,
  read_line : async () -> String?,
  write_line : (String) -> Unit,
) -> Result[String, String] {
  let validate_provider_result = @core.validate_provider(provider)
  guard validate_provider_result is Ok(_) else {
    return Err(
      "Invalid provider configuration: \{validation_error_to_message(validate_provider_result.unwrap_err())}",
    )
  }

  let load_result = try? @core.load_config()
  guard load_result is Ok(config) else {
    return Err("Failed to load config file, \{load_result.unwrap_err()}")
  }

  let existed = config.get_provider(provider.name) is Some(_)
  if existed {
    let overwrite = prompt_yes_no(
      "Provider '\{provider.name}' already exists. Overwrite? (y/N):",
      read_line,
      write_line,
    )
    guard overwrite is Some(confirmed) else {
      return Err("Input aborted while confirming overwrite")
    }
    if !confirmed {
      return Err("Operation canceled")
    }
  }

  let updated_providers = replace_or_append_provider(config.providers, provider)
  let updated_config = @core.Config::{ providers: updated_providers }
  let validate_config_result = @core.validate_config(updated_config)
  guard validate_config_result is Ok(_) else {
    return Err(
      "Invalid configuration: \{validation_error_to_message(validate_config_result.unwrap_err())}",
    )
  }
  let config_path = @core.get_config_path()
  let backup_result = backup_config_before_write(config_path)
  guard backup_result is Ok(_) else {
    return Err("Failed to backup config file: \{backup_result.unwrap_err()}")
  }
  let save_result = save_providers_preserving_other_fields(
    config_path,
    updated_providers,
  )
  guard save_result is Ok(_) else { return Err(save_result.unwrap_err()) }
  if existed {
    Ok("Updated provider '\{provider.name}'")
  } else {
    Ok("Added provider '\{provider.name}'")
  }
}

///|
fn replace_or_append_provider(
  providers : @list.List[@provider.Provider],
  provider : @provider.Provider,
) -> @list.List[@provider.Provider] {
  let existing_name_lower = provider.name.to_lower()
  let provider_array = providers
    .to_array()
    .map(fn(existing) {
      if existing.name.to_lower() == existing_name_lower {
        provider
      } else {
        existing
      }
    })
  if providers.any(fn(existing) {
      existing.name.to_lower() == existing_name_lower
    }) {
    @list.from_array(provider_array)
  } else {
    @list.from_array(provider_array + [provider])
  }
}

///|
fn validation_error_to_message(err : @core.ValidationError) -> String {
  match err {
    @core.ValidationError::EmptyProviderName => "Provider name cannot be empty"
    @core.ValidationError::EmptyApiKey => "Provider API key cannot be empty"
    @core.ValidationError::NoBaseUrls =>
      "Provider must have at least one base URL configured"
    @core.ValidationError::InvalidBaseUrl(url) => "Invalid base URL: \{url}"
    @core.ValidationError::NoModels =>
      "Provider must have at least one model configured"
    @core.ValidationError::DuplicateProviderName(name) =>
      "Duplicate provider name: \{name}"
    @core.ValidationError::EmptyModelName => "Model name cannot be empty"
    @core.ValidationError::InvalidContextWindow(value) =>
      "Invalid context window size: \{value}"
  }
}

///|
const MAX_CONFIG_BACKUPS = 5

///|
fn config_backup_path(config_path : String, index : Int) -> String {
  "\{config_path}.bak.\{index}"
}

///|
fn copy_file(src : String, dst : String) -> Result[Unit, String] {
  let read_result = try? @fs.read_file_to_bytes(src)
  guard read_result is Ok(content) else {
    return Err("\{read_result.unwrap_err()}")
  }
  let write_result = try? @fs.write_bytes_to_file(dst, content)
  guard write_result is Ok(_) else {
    return Err("\{write_result.unwrap_err()}")
  }
  Ok(())
}

///|
fn rotate_backups(
  config_path : String,
  index : Int,
  max_backups : Int,
) -> Result[Unit, String] {
  if index > max_backups {
    return Ok(())
  }
  let recurse_result = rotate_backups(config_path, index + 1, max_backups)
  guard recurse_result is Ok(_) else { return recurse_result }
  let current_slot = config_backup_path(config_path, index)
  if !@fs.path_exists(current_slot) {
    return Ok(())
  }
  if index == max_backups {
    let remove_result = try? @fs.remove_file(current_slot)
    guard remove_result is Ok(_) else {
      return Err("\{remove_result.unwrap_err()}")
    }
    Ok(())
  } else {
    let next_slot = config_backup_path(config_path, index + 1)
    let copy_result = copy_file(current_slot, next_slot)
    guard copy_result is Ok(_) else { return copy_result }
    let remove_result = try? @fs.remove_file(current_slot)
    guard remove_result is Ok(_) else {
      return Err("\{remove_result.unwrap_err()}")
    }
    Ok(())
  }
}

///|
fn backup_config_before_write(config_path : String) -> Result[Unit, String] {
  if !@fs.path_exists(config_path) {
    return Ok(())
  }
  let rotate_result = rotate_backups(config_path, 1, MAX_CONFIG_BACKUPS)
  guard rotate_result is Ok(_) else { return rotate_result }
  copy_file(config_path, config_backup_path(config_path, 1))
}

///|
fn save_providers_preserving_other_fields(
  config_path : String,
  providers : @list.List[@provider.Provider],
) -> Result[Unit, String] {
  let mut config_json = Json::object({})
  if @fs.path_exists(config_path) {
    let read_result = try? @fs.read_file_to_string(config_path)
    guard read_result is Ok(content) else {
      return Err("Failed to read existing config file: \{read_result.unwrap_err()}")
    }
    let parse_result = try? @json.parse(content)
    guard parse_result is Ok(parsed) else {
      return Err("Failed to parse existing config file: \{parse_result.unwrap_err()}")
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
