#if defined(_WIN32)

#include <windows.h>
#include <io.h>

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

#endif
