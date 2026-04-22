///|

///|
const ADD_PROVIDER_TEST_ROOT = "_aswitch_test/add_provider"

///|
fn cleanup_temp_dir(temp_dir : String) -> Unit {
  if !@fs.path_exists(temp_dir) {
    return
  }
  let entries_result = try? @fs.read_dir(temp_dir)
  if entries_result is Ok(entries) {
    for entry in entries {
      let file_path = @path.Path(temp_dir).join(entry).to_string()
      let _ = try? @fs.remove_file(file_path)
    }
  }
  let _ = try? @fs.remove_dir(temp_dir)
}

///|
async fn with_temp_aswitch_home(
  test_suffix : String,
  body : async () -> Unit,
) -> Unit {
  let original_home = @sys.get_env_var("ASWITCH_HOME")
  if !@fs.path_exists("_aswitch_test") {
    try! @fs.create_dir("_aswitch_test")
  }
  if !@fs.path_exists(ADD_PROVIDER_TEST_ROOT) {
    try! @fs.create_dir(ADD_PROVIDER_TEST_ROOT)
  }
  let temp_dir = @path.Path(ADD_PROVIDER_TEST_ROOT)
    .join(test_suffix)
    .to_string()
  cleanup_temp_dir(temp_dir)
  try! @fs.create_dir(temp_dir)
  defer {
    cleanup_temp_dir(temp_dir)
    @sys.set_env_var("ASWITCH_HOME", original_home.unwrap_or(""))
  }
  @sys.set_env_var("ASWITCH_HOME", temp_dir)
  body()
}

///|
fn mock_reader(inputs : Array[String]) -> async () -> String? {
  let mut idx = 0
  fn() {
    if idx >= inputs.length() {
      None
    } else {
      let line = inputs[idx]
      idx += 1
      Some(line)
    }
  }
}

///|
fn mock_writer(logs : Array[String]) -> (String) -> Unit {
  fn(line) { logs.push(line) }
}

///|
fn single_provider(
  name : String,
  api_key : String,
  openai_base_url : String?,
  anthropic_base_url : String?,
  model_names : Array[String],
) -> @provider.Provider {
  @provider.Provider::{
    name,
    api_key,
    openai_base_url,
    anthropic_base_url,
    models: model_names.map(fn(model_name) {
      @provider.Model::new(name=model_name)
    }),
  }
}

///|
async test "run_add_provider_interactive adds provider with multiple models" {
  with_temp_aswitch_home("multi_models", async fn() {
    @core.save_config(@core.Config::new()).unwrap()

    let lines = [
      "openai", "sk-test", "https://api.openai.com/v1", "", "gpt-4o", "y", "gpt-4.1",
      "n",
    ]
    let logs : Array[String] = []
    let result = run_add_provider_interactive(
      mock_reader(lines),
      mock_writer(logs),
    )
    assert_true(result is Ok("Added provider 'openai'"))

    let config = @core.load_config()
    let provider = config.get_provider("openai").unwrap()
    assert_eq(provider.api_key, "sk-test")
    assert_true(provider.openai_base_url is Some("https://api.openai.com/v1"))
    assert_true(provider.anthropic_base_url is None)
    assert_eq(provider.models.length(), 2)
    assert_eq(provider.models[0].name, "gpt-4o")
    assert_eq(provider.models[1].name, "gpt-4.1")
  })
}

///|
async test "run_add_provider_interactive reprompts required fields" {
  with_temp_aswitch_home("reprompt_required", async fn() {
    @core.save_config(@core.Config::new()).unwrap()

    let lines = [
      "", "moonshot", "", "sk-moon", "https://api.moonshot.ai/v1", "", "", "moonshot-v1",
      "n",
    ]
    let logs : Array[String] = []
    let result = run_add_provider_interactive(
      mock_reader(lines),
      mock_writer(logs),
    )
    assert_true(result is Ok("Added provider 'moonshot'"))
    assert_true(
      logs.any(fn(line) {
        line == "This field is required. Please enter a non-empty value."
      }),
    )
  })
}

///|
async test "upsert_provider asks confirmation before overwrite and can cancel" {
  with_temp_aswitch_home("overwrite_cancel", async fn() {
    let initial = single_provider(
      "openai",
      "sk-old",
      Some("https://api.openai.com/v1"),
      None,
      ["gpt-4o"],
    )
    @core.save_config(@core.Config::{ providers: @list.from_array([initial]) }).unwrap()

    let updated = single_provider(
      "OpenAI",
      "sk-new",
      Some("https://api.openai.com/v1"),
      None,
      ["gpt-4.1"],
    )
    let logs : Array[String] = []
    let result = upsert_provider(updated, mock_reader(["n"]), mock_writer(logs))
    assert_true(result is Err("Operation canceled"))

    let config = @core.load_config()
    let provider = config.get_provider("openai").unwrap()
    assert_eq(provider.api_key, "sk-old")
    assert_eq(provider.models[0].name, "gpt-4o")
  })
}

///|
async test "upsert_provider overwrites provider when confirmed" {
  with_temp_aswitch_home("overwrite_confirm", async fn() {
    let initial = single_provider(
      "openai",
      "sk-old",
      Some("https://api.openai.com/v1"),
      None,
      ["gpt-4o"],
    )
    @core.save_config(@core.Config::{ providers: @list.from_array([initial]) }).unwrap()

    let updated = single_provider(
      "openai",
      "sk-new",
      Some("https://api.openai.com/v1"),
      Some("https://api.anthropic.com"),
      ["gpt-4.1", "gpt-4.1-mini"],
    )
    let logs : Array[String] = []
    let result = upsert_provider(updated, mock_reader(["y"]), mock_writer(logs))
    assert_true(result is Ok("Updated provider 'openai'"))

    let config = @core.load_config()
    let provider = config.get_provider("openai").unwrap()
    assert_eq(provider.api_key, "sk-new")
    assert_true(
      provider.anthropic_base_url is Some("https://api.anthropic.com"),
    )
    assert_eq(provider.models.length(), 2)
    assert_eq(provider.models[0].name, "gpt-4.1")
    assert_eq(provider.models[1].name, "gpt-4.1-mini")
  })
}

///|
async test "upsert_provider creates backup before saving updated config" {
  with_temp_aswitch_home("backup_before_save", async fn() {
    let initial = single_provider(
      "openai",
      "sk-old",
      Some("https://api.openai.com/v1"),
      None,
      ["gpt-4o"],
    )
    let initial_config = @core.Config::{
      providers: @list.from_array([initial]),
    }
    @core.save_config(initial_config).unwrap()
    let config_path = @core.get_config_path()

    let updated = single_provider(
      "openai",
      "sk-new",
      Some("https://api.openai.com/v1"),
      None,
      ["gpt-4.1"],
    )
    let logs : Array[String] = []
    let result = upsert_provider(updated, mock_reader(["y"]), mock_writer(logs))
    assert_true(result is Ok("Updated provider 'openai'"))

    let backup_path = "\{config_path}.bak.1"
    assert_true(@fs.path_exists(backup_path))
    let backup_content = try! @fs.read_file_to_string(backup_path)
    let backup_json = try! @json.parse(backup_content)
    let backup_config : @core.Config = try! @json.from_json(backup_json)
    let backup_provider = backup_config.get_provider("openai").unwrap()
    assert_eq(backup_provider.api_key, "sk-old")

    let current_config = @core.load_config()
    let current_provider = current_config.get_provider("openai").unwrap()
    assert_eq(current_provider.api_key, "sk-new")
  })
}
