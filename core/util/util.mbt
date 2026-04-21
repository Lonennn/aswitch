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
/// Generate a human-readable diff between two JSON strings
/// Shows added/removed/changed fields with context
pub fn generate_json_diff(original : String, updated : String) -> String {
  let original_lines = original
    .split("\n")
    .map(fn(s) { s.to_string() })
    .to_array()
  let updated_lines = updated
    .split("\n")
    .map(fn(s) { s.to_string() })
    .to_array()

  let output = []
  let mut i = 0
  let mut j = 0

  while i < original_lines.length() && j < updated_lines.length() {
    if original_lines[i] == updated_lines[j] {
      output.push("  " + original_lines[i])
      i += 1
      j += 1
    } else {
      // Check if line was removed
      let mut found = false
      let mut k = j
      while k < updated_lines.length() {
        if updated_lines[k] == original_lines[i] {
          found = true
          break
        }
        k += 1
      }
      if !found {
        output.push("- " + original_lines[i])
        i += 1
      } else {
        // Check if line was added
        let mut found_original = false
        let mut k = i
        while k < original_lines.length() {
          if original_lines[k] == updated_lines[j] {
            found_original = true
            break
          }
          k += 1
        }
        if !found_original {
          output.push("+ " + updated_lines[j])
          j += 1
        } else {
          // Lines are different
          output.push("- " + original_lines[i])
          output.push("+ " + updated_lines[j])
          i += 1
          j += 1
        }
      }
    }
  }

  // Add remaining removed lines
  while i < original_lines.length() {
    output.push("- " + original_lines[i])
    i += 1
  }

  // Add remaining added lines
  while j < updated_lines.length() {
    output.push("+ " + updated_lines[j])
    j += 1
  }

  output.join("\n")
}
