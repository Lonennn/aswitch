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
    println("Configuration file already exists at: \{path}")
    println(
      "To start with a fresh config, delete the file and run `aswitch init` again.",
    )
    println("To add providers to the existing config, use `aswitch add`.")
    EXIT_CODE_SUCCESS
  }
}
