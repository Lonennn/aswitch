///|
test "OpenClaw get_config_dir returns correct path" {
  // Test that the config directory path is correctly formed
  let path = OpenClaw::get_config_dir()
  assert_true(path.has_suffix(".openclaw"))
}

///|
test "OpenClaw get_config_file_path returns correct path" {
  // Test that the config file path is correctly formed
  let path = OpenClaw::get_config_file_path()
  assert_true(path.has_suffix("openclaw.json"))
}
