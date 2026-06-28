#if defined(_WIN32)

#include <windows.h>
#include <conio.h>
#include <io.h>
#include <stdio.h>

/// Check whether stdout is a console (TTY) on Windows.
/// Returns 1 if stdout is a TTY, 0 otherwise.
static int aswitch_stdout_is_tty_windows(void) {
  HANDLE h = GetStdHandle(STD_OUTPUT_HANDLE);
  if (h == INVALID_HANDLE_VALUE || h == NULL) {
    return 0;
  }
  DWORD mode;
  if (!GetConsoleMode(h, &mode)) {
    return 0;
  }
  return 1;
}

/// Prepare stdout for ANSI alternate-screen sequences.
static int aswitch_prepare_stdout_for_alternate_screen_windows(void) {
  HANDLE h = GetStdHandle(STD_OUTPUT_HANDLE);
  if (h == INVALID_HANDLE_VALUE || h == NULL) {
    return 0;
  }
  DWORD mode;
  if (!GetConsoleMode(h, &mode)) {
    return 0;
  }
  DWORD new_mode = mode | ENABLE_VIRTUAL_TERMINAL_PROCESSING;
  if (!SetConsoleMode(h, new_mode)) {
    return 0;
  }
  return 1;
}

/// Wait for a single key press without echoing it.
static int aswitch_wait_for_any_key_windows(void) {
  int ch = _getch();
  return ch == EOF ? 0 : 1;
}

#endif
