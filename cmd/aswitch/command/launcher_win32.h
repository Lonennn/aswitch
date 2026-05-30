#if defined(_WIN32)

#include <windows.h>
#include <process.h>

/// Build a properly-escaped command line string from argv for CreateProcess.
/// Follows the MSVCRT parsing rules used by CommandLineToArgvW.
/// Caller must free the returned pointer.
static char *build_windows_cmdline(char **argv) {
  size_t total = 1; // null terminator
  for (int i = 0; argv[i] != NULL; i++) {
    total += strlen(argv[i]) * 2 + 3; // worst case: every char escaped + quotes + space
  }

  char *cmdline = (char *)malloc(total);
  if (cmdline == NULL) {
    return NULL;
  }

  char *dest = cmdline;
  for (int i = 0; argv[i] != NULL; i++) {
    if (i > 0) {
      *dest++ = ' ';
    }

    const char *arg = argv[i];
    size_t arg_len = strlen(arg);

    int needquote = (arg_len == 0);
    if (!needquote) {
      for (const char *p = arg; *p; p++) {
        if (*p == ' ' || *p == '\t') {
          needquote = 1;
          break;
        }
      }
    }

    if (!needquote) {
      memcpy(dest, arg, arg_len);
      dest += arg_len;
      continue;
    }

    *dest++ = '"';

    int backslash_count = 0;
    for (const char *p = arg; *p; p++) {
      if (*p == '\\') {
        backslash_count++;
      } else if (*p == '"') {
        for (int j = 0; j < backslash_count; j++) {
          *dest++ = '\\';
        }
        backslash_count = 0;
        *dest++ = '\\';
        *dest++ = '"';
      } else {
        for (int j = 0; j < backslash_count; j++) {
          *dest++ = '\\';
        }
        backslash_count = 0;
        *dest++ = *p;
      }
    }

    for (int j = 0; j < backslash_count; j++) {
      *dest++ = '\\';
    }
    for (int j = 0; j < backslash_count; j++) {
      *dest++ = '\\';
    }

    *dest++ = '"';
  }

  *dest = '\0';
  return cmdline;
}

/// Launch command on Windows using CreateProcess + WaitForSingleObject.
/// On success this function does not return (_exit is called with child's code).
/// On failure returns a negative errno-style code.
static int launch_command_windows(char **argv) {
  char *cmdline = build_windows_cmdline(argv);
  if (cmdline == NULL) {
    return -12; // ENOMEM
  }

  STARTUPINFOA si;
  memset(&si, 0, sizeof(si));
  si.cb = sizeof(si);

  PROCESS_INFORMATION pi;
  memset(&pi, 0, sizeof(pi));

  if (!CreateProcessA(NULL, cmdline, NULL, NULL, TRUE, 0, NULL, NULL, &si, &pi)) {
    DWORD err = GetLastError();
    free(cmdline);
    switch (err) {
      case ERROR_FILE_NOT_FOUND:
      case ERROR_PATH_NOT_FOUND:
        return -2;  // ENOENT
      case ERROR_ACCESS_DENIED:
        return -13; // EACCES
      case ERROR_INVALID_PARAMETER:
        return -22; // EINVAL
      case ERROR_BAD_FORMAT:
        return -8;  // ENOEXEC
      case ERROR_NOT_ENOUGH_MEMORY:
        return -12; // ENOMEM
      default:
        return -(int)err;
    }
  }

  free(cmdline);
  CloseHandle(pi.hThread);

  WaitForSingleObject(pi.hProcess, INFINITE);

  DWORD exit_code;
  GetExitCodeProcess(pi.hProcess, &exit_code);
  CloseHandle(pi.hProcess);

  _exit((int)exit_code);
}

#endif