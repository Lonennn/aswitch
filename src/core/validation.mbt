///|
/// Configuration validation module

///|
/// Validation error type
pub enum ValidationError {
  /// Provider has empty name
  EmptyProviderName
  /// Provider has empty API key
  EmptyApiKey
  /// Provider has no API base URLs configured
  NoBaseUrls
  /// Provider has invalid base URL format
  InvalidBaseUrl(String)
  /// Provider has no models configured
  NoModels
  /// Duplicate provider name found in config
  DuplicateProviderName(String)
  /// Model has empty name
  EmptyModelName
  /// Model has invalid context window size
  InvalidContextWindow(Int)
} derive(Debug, Eq)

///|
/// Validate a single Provider configuration
pub fn validate_provider(
  provider : @provider.Provider,
) -> Result[Unit, ValidationError] {
  // Check empty name
  if provider.name.trim().is_empty() {
    return Err(EmptyProviderName)
  }

  // Check empty API key
  if provider.api_key.trim().is_empty() {
    return Err(EmptyApiKey)
  }

  // Check at least one base URL exists
  if provider.openai_base_url is None && provider.anthropic_base_url is None {
    return Err(NoBaseUrls)
  }

  // Validate base URL format if present
  let validate_url = fn(url : String) -> Result[Unit, ValidationError] {
    if !url.has_prefix("http://") && !url.has_prefix("https://") {
      return Err(InvalidBaseUrl(url))
    }
    Ok(())
  }

  if provider.openai_base_url is Some(url) {
    let result = validate_url(url)
    match result {
      Ok(_) => ()
      Err(e) => return Err(e)
    }
  }

  if provider.anthropic_base_url is Some(url) {
    let result = validate_url(url)
    match result {
      Ok(_) => ()
      Err(e) => return Err(e)
    }
  }

  // Check at least one model
  if provider.models.is_empty() {
    return Err(NoModels)
  }

  // Validate each model
  for model in provider.models.iter() {
    let result = validate_model(model)
    match result {
      Ok(_) => ()
      Err(e) => return Err(e)
    }
  }

  Ok(())
}

///|
pub fn validation_error_message(err : ValidationError) -> String {
  match err {
    EmptyProviderName => "Provider name cannot be empty"
    EmptyApiKey => "Provider API key cannot be empty"
    NoBaseUrls => "Provider must have at least one base URL configured"
    InvalidBaseUrl(url) => "Invalid base URL: \{url}"
    NoModels => "Provider must have at least one model configured"
    DuplicateProviderName(name) => "Duplicate provider name: \{name}"
    EmptyModelName => "Model name cannot be empty"
    InvalidContextWindow(value) => "Invalid context window size: \{value}"
  }
}

///|
/// Validate a single Model configuration
fn validate_model(model : @provider.Model) -> Result[Unit, ValidationError] {
  if model.name.trim().is_empty() {
    return Err(EmptyModelName)
  }

  if model.context_limit is Some(limit) && limit <= 0 {
    return Err(InvalidContextWindow(limit))
  }

  Ok(())
}

///|
/// Validate entire Config structure
pub fn validate_config(config : Config) -> Result[Unit, ValidationError] {
  // Check for duplicate provider names (case-insensitive)
  let mut seen_names = @list.new()
  for provider in config.providers.iter() {
    let lower_name = provider.name.to_lower()
    if seen_names.contains(lower_name) {
      return Err(DuplicateProviderName(provider.name))
    }
    seen_names = @list.cons(lower_name, seen_names)

    // Validate each provider
    let result = validate_provider(provider)
    match result {
      Ok(_) => ()
      Err(e) => return Err(e)
    }
  }

  Ok(())
}
