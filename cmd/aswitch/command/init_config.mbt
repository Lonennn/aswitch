///|
/// Execution commands for aswitch CLI
const SCHEMA_URL = "https://raw.githubusercontent.com/Lonennn/aswitch/master/asset/aswitch.schema.json"

///|
/// Initialize configuration file with JSON schema reference if it doesn't exist
pub fn init_config() -> Int {
  let path = @core.get_config_path()
  if !@fs.path_exists(path) {
    let config_json : Json = {
      "$schema": Json::string(SCHEMA_URL),
      "providers": Json::array([]),
    }
    let content = config_json.stringify(indent=4)
    let write_result = try? @fs.write_string_to_file(path, content)
    match write_result {
      Ok(_) => {
        println("Configuration initialized at: \{path}")
        EXIT_CODE_SUCCESS
      }
      Err(e) => {
        println("Error initializing config: \{e}")
        EXIT_CODE_CONFIG_ERROR
      }
    }
  } else {
    let read_result = try? @fs.read_file_to_string(path)
    match read_result {
      Ok(content) => {
        let parse_result = try? @json.parse(content)
        match parse_result {
          Ok(Json::Object(entries)) =>
            if entries.contains("$schema") {
              println("Configuration file already exists at: \{path}")
              println("Schema field already exists; no changes made.")
              println(
                "To add providers to the existing config, use `aswitch add`.",
              )
              EXIT_CODE_SUCCESS
            } else {
              entries["$schema"] = Json::string(SCHEMA_URL)
              let updated_content = Json::object(entries).stringify(indent=4)
              let write_result = try? @fs.write_string_to_file(
                path, updated_content,
              )
              match write_result {
                Ok(_) => {
                  println("Configuration file already exists at: \{path}")
                  println("Added missing $schema field to existing config.")
                  println(
                    "To add providers to the existing config, use `aswitch add`.",
                  )
                  EXIT_CODE_SUCCESS
                }
                Err(e) => {
                  println("Error patching config schema field: \{e}")
                  EXIT_CODE_CONFIG_ERROR
                }
              }
            }
          Ok(_) => {
            println(
              "Error patching config schema field: config root must be a JSON object",
            )
            EXIT_CODE_CONFIG_ERROR
          }
          Err(e) => {
            println("Error patching config schema field: \{e}")
            EXIT_CODE_CONFIG_ERROR
          }
        }
      }
      Err(e) => {
        println("Error patching config schema field: \{e}")
        EXIT_CODE_CONFIG_ERROR
      }
    }
  }
}
