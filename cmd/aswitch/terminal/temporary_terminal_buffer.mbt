///|
/// Display text in a temporary terminal buffer when stdout is a TTY.
/// On POSIX systems this routes through a pager. On Windows it routes through
/// the Windows Terminal alternate screen buffer when available.
/// Falls back to direct stdout print when:
/// - stdout is not a TTY (piped/redirected)
/// - the temporary buffer backend is unavailable
/// - the backend fails to launch
pub async fn display_in_temporary_terminal_buffer(text : String) -> Unit {
  if !is_stdout_tty() {
    println(text)
    return
  }
  display_in_temporary_terminal_buffer_impl(text)
}

///|
#cfg(platform="windows")
async fn display_in_temporary_terminal_buffer_impl(text : String) -> Unit {
  if is_windows_terminal() && display_with_windows_alternate_screen(text) {
    return
  }
  @stdio.stderr.write(
    "Warning: Windows alternate screen is unavailable. Command may remain in terminal scrollback history.\n",
  )
  println(text)
  return
}

///|
#cfg(not(platform="windows"))
async fn display_in_temporary_terminal_buffer_impl(text : String) -> Unit {
  display_with_pager(text)
}
