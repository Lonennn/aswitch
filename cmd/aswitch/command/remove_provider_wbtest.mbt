///|
async test "run_remove_provider removes provider after confirmation" {
  with_temp_aswitch_home("remove_confirmed", async fn() {
    let openai = single_provider(
      "openai",
      "sk-openai",
      Some("https://api.openai.com/v1"),
      None,
      ["gpt-4o"],
    )
    let anthropic = single_provider(
      "anthropic",
      "sk-ant",
      None,
      Some("https://api.anthropic.com"),
      ["claude-3-7-sonnet"],
    )
    @core.save_config(@core.Config::{
      providers: @list.from_array([openai, anthropic]),
    }).unwrap()

    let logs : Array[String] = []
    let result = run_remove_provider(
      "openai",
      mock_reader(["y"]),
      mock_writer(logs),
    )
    assert_eq(result, (EXIT_CODE_SUCCESS, "Removed provider 'openai'"))
    assert_true(
      logs.any(fn(line) { line == "Remove provider 'openai'? (y/N):" }),
    )

    let updated = @core.load_config()
    assert_true(updated.get_provider("openai") is None)
    assert_true(updated.get_provider("anthropic") is Some(_))
  })
}

///|
async test "run_remove_provider supports case-insensitive provider lookup" {
  with_temp_aswitch_home("remove_case_insensitive", async fn() {
    let openai = single_provider(
      "OpenAI",
      "sk-openai",
      Some("https://api.openai.com/v1"),
      None,
      ["gpt-4o"],
    )
    @core.save_config(@core.Config::{ providers: @list.from_array([openai]) }).unwrap()

    let result = run_remove_provider(
      "openai",
      mock_reader(["y"]),
      mock_writer([]),
    )
    assert_eq(result, (EXIT_CODE_SUCCESS, "Removed provider 'OpenAI'"))

    let updated = @core.load_config()
    assert_true(updated.providers.is_empty())
  })
}

///|
async test "run_remove_provider returns unknown provider exit code" {
  with_temp_aswitch_home("remove_unknown", async fn() {
    @core.save_config(@core.Config::new()).unwrap()

    let result = run_remove_provider(
      "not-found",
      mock_reader(["y"]),
      mock_writer([]),
    )
    assert_eq(
      result,
      (EXIT_CODE_UNKNOWN_PROVIDER, "Error: Unknown provider 'not-found'"),
    )
  })
}

///|
async test "run_remove_provider can cancel operation" {
  with_temp_aswitch_home("remove_cancel", async fn() {
    let openai = single_provider(
      "openai",
      "sk-openai",
      Some("https://api.openai.com/v1"),
      None,
      ["gpt-4o"],
    )
    @core.save_config(@core.Config::{ providers: @list.from_array([openai]) }).unwrap()

    let result = run_remove_provider(
      "openai",
      mock_reader(["n"]),
      mock_writer([]),
    )
    assert_eq(result, (EXIT_CODE_CONFIG_ERROR, "Operation canceled"))

    let updated = @core.load_config()
    assert_true(updated.get_provider("openai") is Some(_))
  })
}

///|
async test "run_remove_provider creates backup and preserves non-provider fields" {
  with_temp_aswitch_home("remove_backup_and_preserve_fields", async fn() {
    let config_path = @core.get_config_path()
    let content = "{\n" +
      "    \"$schema\": \"./asset/aswitch.schema.json\",\n" +
      "    \"notes\": \"keep me\",\n" +
      "    \"providers\": [\n" +
      "        {\n" +
      "            \"name\": \"openai\",\n" +
      "            \"api_key\": \"sk-openai\",\n" +
      "            \"openai_base_url\": \"https://api.openai.com/v1\",\n" +
      "            \"models\": [\n" +
      "                { \"name\": \"gpt-4o\" }\n" +
      "            ]\n" +
      "        }\n" +
      "    ]\n" +
      "}\n"
    try! @fs.write_string_to_file(config_path, content)

    let result = run_remove_provider(
      "openai",
      mock_reader(["y"]),
      mock_writer([]),
    )
    assert_eq(result, (EXIT_CODE_SUCCESS, "Removed provider 'openai'"))

    let backup_path = "\{config_path}.bak.1"
    assert_true(@fs.path_exists(backup_path))

    let current_content = try! @fs.read_file_to_string(config_path)
    let current_json = try! @json.parse(current_content)
    match current_json {
      Json::Object(entries) => {
        assert_true(
          entries["$schema"] is Json::String("./asset/aswitch.schema.json"),
        )
        assert_true(entries["notes"] is Json::String("keep me"))
      }
      _ => fail("Expected config JSON object after remove")
    }

    let current_config : @core.Config = try! @json.from_json(current_json)
    assert_true(current_config.providers.is_empty())

    let backup_content = try! @fs.read_file_to_string(backup_path)
    let backup_json = try! @json.parse(backup_content)
    let backup_config : @core.Config = try! @json.from_json(backup_json)
    assert_eq(backup_config.providers.length(), 1)
    assert_true(backup_config.get_provider("openai") is Some(_))
  })
}
