///|
#cfg(platform="windows")
extern "c" fn aswitch_prepare_stdout_for_alternate_screen() -> Int = "aswitch_prepare_stdout_for_alternate_screen"

///|
#cfg(platform="windows")
extern "c" fn aswitch_wait_for_any_key() -> Int = "aswitch_wait_for_any_key"

///|
#cfg(platform="windows")
let windows_alternate_screen_enter = "\u001b[?1049h\u001b[2J\u001b[H"

///|
#cfg(platform="windows")
let windows_alternate_screen_exit = "\u001b[?1049l"

///|
#cfg(platform="windows")
let windows_alternate_screen_prompt = "\nPress any key to close..."

///|
#cfg(platform="windows")
fn is_windows_terminal() -> Bool {
  match @sys.get_env_var("WT_SESSION") {
    Some(session) => !@util.is_blank(session)
    None => false
  }
}

///|
#cfg(platform="windows")
async fn display_with_windows_alternate_screen(text : String) -> Bool {
  if aswitch_prepare_stdout_for_alternate_screen() == 0 {
    return false
  }
  let text_with_newline = if text.has_suffix("\n") { text } else { text + "\n" }
  @stdio.stdout.write(windows_alternate_screen_enter)
  @stdio.stdout.write(text_with_newline)
  @stdio.stdout.write(windows_alternate_screen_prompt)
  ignore(aswitch_wait_for_any_key())
  @stdio.stdout.write(windows_alternate_screen_exit)
  true
}

///|
#cfg(not(platform="windows"))
fn can_use_windows_alternate_screen() -> Bool {
  false
}

///|
#cfg(not(platform="windows"))
async fn display_with_windows_alternate_screen(_text : String) -> Bool {
  false
}
