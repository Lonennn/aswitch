///|
#cfg(platform="windows")
test "can_use_windows_alternate_screen requires Windows Terminal" {
  let original_wt_session = @env.get_env_var("WT_SESSION")
  @env.set_env_var("WT_SESSION", "1")
  assert_true(is_windows_terminal())
  @env.unset_env_var("WT_SESSION")
  assert_false(is_windows_terminal())
  match original_wt_session {
    Some(v) => @env.set_env_var("WT_SESSION", v)
    None => @env.unset_env_var("WT_SESSION")
  }
}
