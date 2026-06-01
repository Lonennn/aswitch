///|
extern "c" fn aswitch_is_stdout_tty() -> Int = "aswitch_is_stdout_tty"

///|
/// Check whether stdout is connected to a terminal (TTY).
pub fn is_stdout_tty() -> Bool {
  aswitch_is_stdout_tty() != 0
}

///|
/// Resolve the pager command to use.
/// Priority: $PAGER environment variable → "less" → None
pub fn resolve_pager() -> String? {
  match @sys.get_env_var("PAGER") {
    Some(pager) =>
      if @util.is_blank(pager) {
        None
      } else {
        Some(pager.trim().to_owned())
      }
    None => Some("less")
  }
}

///|
/// Split a pager command string into executable and arguments.
/// e.g. "less -R" -> ("less", ["-R"])
pub fn parse_pager_cmd(pager : String) -> (String, Array[String]) {
  if pager.is_empty() {
    return ("", [])
  }
  let parts = pager
    .replace_all(old="\t", new=" ")
    .split(" ")
    .filter(fn(s) { s.length() > 0 })
    .map(fn(s) { s.to_owned() })
    .collect()
  match parts {
    [] => (pager, [])
    [cmd, .. rest] => (cmd, rest.to_owned())
  }
}

///|
/// Display text through a pager when stdout is a TTY.
/// Falls back to direct stdout print when:
/// - stdout is not a TTY (piped/redirected)
/// - no pager is available
/// - the pager fails to launch
///
/// Threat model: The caller (aswitch CLI) controls both the text content and
/// the PAGER environment variable. We inherit the current process environment.
/// Sensitive data only flows through the pipe to the pager subprocess; if the
/// pager fails, we fall back to stdout with a warning.
pub async fn display_with_pager(text : String) -> Unit {
  if !is_stdout_tty() {
    println(text)
    return
  }
  match resolve_pager() {
    None => {
      @stdio.stderr.write(
        "Warning: No pager available. Command may remain in terminal scrollback history.\n",
      )
      println(text)
    }
    Some(pager) => {
      let (pager_cmd, pager_args) = parse_pager_cmd(pager)
      let text_with_newline = if text.has_suffix("\n") {
        text
      } else {
        text + "\n"
      }
      try {
        let (stdin_input, stdin_write) = @process.write_to_process()
        let exit_code = @async.with_task_group(group => {
          let pager_task = group.spawn(() => {
            @process.run(
              pager_cmd,
              pager_args,
              stdin=stdin_input,
              stdout=@stdio.stdout,
              stderr=@stdio.stderr,
            )
          })
          stdin_write.write(text_with_newline)
          stdin_write.close()
          pager_task.wait()
        })
        // The pager's exit code is intentionally ignored:
        // the user may quit with 'q' (exit 0) or interrupt (non-zero),
        // neither of which is an aswitch error.
        ignore(exit_code)
      } catch {
        err => {
          @stdio.stderr.write(
            "Warning: Pager '\{pager}' failed (\{err}). Command may remain in terminal scrollback history.\n",
          )
          println(text)
        }
      }
    }
  }
}
