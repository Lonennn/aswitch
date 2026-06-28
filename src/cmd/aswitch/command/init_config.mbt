///|
/// Execution commands for aswitch CLI
const SCHEMA_URL = "https://raw.githubusercontent.com/Lonennn/aswitch/master/asset/aswitch.schema.json"

///|
/// Initialize configuration file with JSON schema reference if it doesn't exist
pub fn init_config() -> Int {
  let path = @core.get_config_path()
  if !@fs.path_exists(path) {
    let parent = @path.Path(path).dirname()

    @util.create_dirs(parent) catch {
      e => {
        println("Failed to create directory \{parent}: \{e}")
        return EXIT_CODE_FAILED_TO_CREATE_DIR
      }
    }

    let config_json : Json = {
      "$schema": Json::string(SCHEMA_URL),
      "providers": Json::array([]),
    }
    let content = config_json.stringify(indent=4)
    try @fs.write_string_to_file(path, content) catch {
      e => {
        println("Error initializing config: \{e}")
        EXIT_CODE_CONFIG_ERROR
      }
    } noraise {
      _ => {
        println("Configuration initialized at: \{path}")
        EXIT_CODE_SUCCESS
      }
    }
  } else {
    let content = @fs.read_file_to_string(path) catch {
      e => {
        println("Error patching config schema field: \{e}")
        return EXIT_CODE_CONFIG_ERROR
      }
    }
    let parsed = @json.parse(content) catch {
      e => {
        println("Error patching config schema field: \{e}")
        return EXIT_CODE_CONFIG_ERROR
      }
    }
    match parsed {
      Json::Object(entries) =>
        if entries.contains("$schema") {
          println("Configuration file already exists at: \{path}")
          println("Schema field already exists; no changes made.")
          println("To add providers to the existing config, use `aswitch add`.")
          EXIT_CODE_SUCCESS
        } else {
          entries["$schema"] = Json::string(SCHEMA_URL)
          let updated_content = Json::object(entries).stringify(indent=4)
          try @fs.write_string_to_file(path, updated_content) catch {
            e => {
              println("Error patching config schema field: \{e}")
              EXIT_CODE_CONFIG_ERROR
            }
          } noraise {
            _ => {
              println("Configuration file already exists at: \{path}")
              println("Added missing $schema field to existing config.")
              println(
                "To add providers to the existing config, use `aswitch add`.",
              )
              EXIT_CODE_SUCCESS
            }
          }
        }
      _ => {
        println(
          "Error patching config schema field: config root must be a JSON object",
        )
        EXIT_CODE_CONFIG_ERROR
      }
    }
  }
}
