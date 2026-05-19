///|
/// Get the user's home directory (cross-platform)
/// Tries HOME (Unix/macOS), then USERPROFILE (Windows)
pub fn get_user_home() -> String {
  match @sys.get_env_var("HOME") {
    Some(home) => home
    None =>
      match @sys.get_env_var("USERPROFILE") {
        Some(profile) => profile
        None => "."
      }
  }
}

///|
/// Get the default base directory for aswitch files
fn get_default_aswitch_home() -> @path.Path {
  let user_home = get_user_home()
  @path.Path::join(user_home, ".aswitch")
}

///|
/// Get the base directory for aswitch files
/// Tries ASWITCH_HOME env var first, then uses user home directory
pub fn get_aswitch_home() -> String {
  match @sys.get_env_var("ASWITCH_HOME") {
    Some(custom_home) => {
      let trimmed = custom_home.trim()
      if trimmed.is_empty() {
        "."
      } else {
        trimmed.to_owned()
      }
    }
    None => get_default_aswitch_home().to_string()
  }
}
