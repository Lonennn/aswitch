///|
#cfg(platform="windows")
const DEFAULT_PAGER = "more.com"

///|
#cfg(not(platform="windows"))
const DEFAULT_PAGER = "less"

///|
test "resolve_pager returns PAGER env var when set" {
  let original = @sys.get_env_var("PAGER")
  @sys.set_env_var("PAGER", "custom-pager")
  let result = resolve_pager()
  assert_true(result is Some("custom-pager"))
  match original {
    Some(v) => @sys.set_env_var("PAGER", v)
    None => @sys.unset_env_var("PAGER")
  }
}

///|
test "resolve_pager returns platform default when PAGER is unset" {
  let original = @sys.get_env_var("PAGER")
  @sys.unset_env_var("PAGER")
  let result = resolve_pager()
  assert_true(result == Some(DEFAULT_PAGER))
  match original {
    Some(v) => @sys.set_env_var("PAGER", v)
    None => @sys.unset_env_var("PAGER")
  }
}

///|
test "resolve_pager ignores WT_SESSION when PAGER is unset" {
  let original_pager = @sys.get_env_var("PAGER")
  let original_wt_session = @sys.get_env_var("WT_SESSION")
  @sys.unset_env_var("PAGER")
  @sys.set_env_var("WT_SESSION", "1")
  let result = resolve_pager()
  assert_true(result == Some(DEFAULT_PAGER))
  match original_pager {
    Some(v) => @sys.set_env_var("PAGER", v)
    None => @sys.unset_env_var("PAGER")
  }
  match original_wt_session {
    Some(v) => @sys.set_env_var("WT_SESSION", v)
    None => @sys.unset_env_var("WT_SESSION")
  }
}

///|
test "resolve_pager returns None when PAGER is empty" {
  let original = @sys.get_env_var("PAGER")
  @sys.set_env_var("PAGER", "")
  let result = resolve_pager()
  assert_true(result is None)
  match original {
    Some(v) => @sys.set_env_var("PAGER", v)
    None => @sys.unset_env_var("PAGER")
  }
}

///|
test "resolve_pager returns None when PAGER is whitespace only" {
  let original = @sys.get_env_var("PAGER")
  @sys.set_env_var("PAGER", "   \t  ")
  let result = resolve_pager()
  assert_true(result is None)
  match original {
    Some(v) => @sys.set_env_var("PAGER", v)
    None => @sys.unset_env_var("PAGER")
  }
}

///|
test "resolve_pager trims leading and trailing whitespace" {
  let original = @sys.get_env_var("PAGER")
  @sys.set_env_var("PAGER", "  less -R  ")
  let result = resolve_pager()
  assert_true(result is Some("less -R"))
  match original {
    Some(v) => @sys.set_env_var("PAGER", v)
    None => @sys.unset_env_var("PAGER")
  }
}

///|
test "parse_pager_cmd splits command and arguments" {
  let (cmd, args) = parse_pager_cmd("less -R -F")
  assert_true(cmd == "less")
  assert_true(args == ["-R", "-F"])
}

///|
test "parse_pager_cmd handles tabs as separators" {
  let (cmd, args) = parse_pager_cmd("less\t-R\t-F")
  assert_true(cmd == "less")
  assert_true(args == ["-R", "-F"])
}

///|
test "parse_pager_cmd handles multiple consecutive spaces" {
  let (cmd, args) = parse_pager_cmd("less   -R    -F")
  assert_true(cmd == "less")
  assert_true(args == ["-R", "-F"])
}

///|
test "parse_pager_cmd returns empty args for bare command" {
  let (cmd, args) = parse_pager_cmd("less")
  assert_true(cmd == "less")
  assert_true(args == [])
}

///|
test "parse_pager_cmd handles empty string" {
  let (cmd, args) = parse_pager_cmd("")
  assert_true(cmd == "")
  assert_true(args == [])
}
