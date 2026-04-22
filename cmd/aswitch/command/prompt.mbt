///|
async fn read_stdin_line() -> String? {
  @stdio.stdin.read_until("\n")
}
