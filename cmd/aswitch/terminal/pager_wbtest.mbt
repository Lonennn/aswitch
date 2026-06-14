///|
#cfg(platform="windows")
test "can_use_windows_alternate_screen requires Windows Terminal" {
  let original_wt_session = @sys.get_env_var("WT_SESSION")
  @sys.set_env_var("WT_SESSION", "1")
  assert_true(is_windows_terminal())
  @sys.unset_env_var("WT_SESSION")
  assert_false(is_windows_terminal())
  match original_wt_session {
    Some(v) => @sys.set_env_var("WT_SESSION", v)
    None => @sys.unset_env_var("WT_SESSION")
  }
}
