#include <moonbit.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#if defined(_WIN32)
#include <process.h>
#else
#include <unistd.h>
#endif

/// @brief Replace the current process with the specified command.
/// @param executable Null-terminated UTF-8 string of the executable to run.
/// @param args Array of null-terminated argument strings.
/// @return -1 on error (only reached if exec fails).
MOONBIT_FFI_EXPORT
int aswitch_launch_command(moonbit_bytes_t executable, void **args) {
  int arg_count = (int)Moonbit_array_length(args);

  // Build argv: [executable, arg0, arg1, ..., NULL]
  char **argv = (char **)malloc((arg_count + 2) * sizeof(char *));
  if (argv == NULL) {
    return -1;
  }

  argv[0] = (char *)executable;
  for (int i = 0; i < arg_count; i++) {
    argv[i + 1] = (char *)args[i];
  }
  argv[arg_count + 1] = NULL;

#if defined(_WIN32)
  _execvp((char *)executable, argv);
#else
  execvp((char *)executable, argv);
#endif

  // Only reached if execvp/_execvp fails.
  const int saved_errno = errno;
  free(argv);
  return -saved_errno;
}
