#include <moonbit.h>

#if defined(_WIN32)
#include "tty_win32.h"
#else
#include <unistd.h>
#endif

/// @brief Check whether stdout is connected to a terminal (TTY).
/// @return 1 if stdout is a TTY, 0 otherwise.
MOONBIT_FFI_EXPORT
int aswitch_is_stdout_tty(void) {
#if defined(_WIN32)
  return aswitch_stdout_is_tty_windows();
#else
  return isatty(STDOUT_FILENO) ? 1 : 0;
#endif
}
