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
