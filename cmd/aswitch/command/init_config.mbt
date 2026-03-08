///|
/// Execution commands for aswitch CLI

///|
/// Initialize configuration file with JSON schema reference if it doesn't exist
pub fn init_config() -> Int {
  let path = @core.get_config_path()
  if !@fs.path_exists(path) {
    let config = @core.Config::new()
    match @core.save_config(config) {
      Ok(_) => {
        println("Configuration initialized at: \{path}")
        println(
          "Add {\"$schema\": \"./core/aswitch.schema.json\"} to enable editor IntelliSense",
        )
        EXIT_CODE_SUCCESS
      }
      Err(e) => {
        println("Error initializing config: \{e}")
        EXIT_CODE_CONFIG_ERROR
      }
    }
  } else {
    println("Configuration file already exists at: \{path}")
    println("Remove the file to re-initialize")
    EXIT_CODE_SUCCESS
  }
}
