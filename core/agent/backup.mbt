///|
/// Backup management for agent config files.

///|
const DEFAULT_MAX_BACKUPS = 5

///|
fn backup_file_path(config_path : String, index : Int) -> String {
  "\{config_path}.bak.\{index}"
}

///|
fn copy_file(src : String, dst : String) -> Unit raise Error {
  let read_result = try? @fs.read_file_to_bytes(src)
  guard read_result is Ok(content) else { raise read_result.unwrap_err() }
  let write_result = try? @fs.write_bytes_to_file(dst, content)
  guard write_result is Ok(_) else { raise write_result.unwrap_err() }
}

///|
fn rotate_backups(
  config_path : String,
  index : Int,
  max_backups : Int,
) -> Unit raise Error {
  if index > max_backups {
    ()
  } else {
    rotate_backups(config_path, index + 1, max_backups)
    let current_slot = backup_file_path(config_path, index)
    if @fs.path_exists(current_slot) {
      if index == max_backups {
        let remove_result = try? @fs.remove_file(current_slot)
        guard remove_result is Ok(_) else { raise remove_result.unwrap_err() }
      } else {
        let next_slot = backup_file_path(config_path, index + 1)
        copy_file(current_slot, next_slot)
        let remove_result = try? @fs.remove_file(current_slot)
        guard remove_result is Ok(_) else { raise remove_result.unwrap_err() }
      }
    }
  }
}

///|
fn backup_config_before_write(config_path : String) -> Unit raise Error {
  if !@fs.path_exists(config_path) {
    return ()
  }
  rotate_backups(config_path, 1, DEFAULT_MAX_BACKUPS)
  let latest_backup = backup_file_path(config_path, 1)
  copy_file(config_path, latest_backup)
}

///|
fn write_config_with_backup(
  config_path : String,
  content : String,
) -> Unit raise Error {
  backup_config_before_write(config_path)
  let write_result = try? @fs.write_string_to_file(config_path, content)
  guard write_result is Ok(_) else { raise write_result.unwrap_err() }
}
