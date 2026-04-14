///|
/// Whitebox tests for backup rotation behavior.

///|
fn test_dir(name : String) -> String {
  @path.Path::join("/tmp", name).to_string()
}

///|
fn join_path(dir : String, filename : String) -> String {
  @path.Path::join(dir, filename).to_string()
}

///|
fn cleanup_dir(dir : String) -> Unit {
  if !@fs.path_exists(dir) {
    return ()
  }
  let entries_result = try? @fs.read_dir(dir)
  match entries_result {
    Ok(entries) =>
      for entry in entries {
        let path = join_path(dir, entry)
        let _ = try? @fs.remove_file(path)
      }
    Err(_) => ()
  }
  let _ = try? @fs.remove_dir(dir)
}

///|
fn prepare_dir(dir : String) -> Unit {
  cleanup_dir(dir)
  try! @fs.create_dir(dir)
}

///|
fn write_text(path : String, content : String) -> Unit {
  try! @fs.write_string_to_file(path, content)
}

///|
fn read_text(path : String) -> String {
  try! @fs.read_file_to_string(path)
}

///|
test "backup_config_before_write creates first backup" {
  let dir = test_dir("aswitch-backup-test-first")
  prepare_dir(dir)

  let config_path = join_path(dir, "settings.json")
  write_text(config_path, "v1")

  backup_config_before_write(config_path)

  let backup1 = backup_file_path(config_path, 1)
  assert_true(@fs.path_exists(backup1))
  assert_eq(read_text(backup1), "v1")
  assert_eq(read_text(config_path), "v1")
  assert_true(!@fs.path_exists(backup_file_path(config_path, 2)))

  cleanup_dir(dir)
}

///|
test "backup_config_before_write keeps only latest five backups" {
  let dir = test_dir("aswitch-backup-test-rotation")
  prepare_dir(dir)

  let config_path = join_path(dir, "settings.json")
  write_text(config_path, "v0")

  for i in 1..<=7 {
    backup_config_before_write(config_path)
    write_text(config_path, "v\{i}")
  }

  assert_eq(read_text(backup_file_path(config_path, 1)), "v6")
  assert_eq(read_text(backup_file_path(config_path, 2)), "v5")
  assert_eq(read_text(backup_file_path(config_path, 3)), "v4")
  assert_eq(read_text(backup_file_path(config_path, 4)), "v3")
  assert_eq(read_text(backup_file_path(config_path, 5)), "v2")
  assert_true(!@fs.path_exists(backup_file_path(config_path, 6)))

  cleanup_dir(dir)
}
