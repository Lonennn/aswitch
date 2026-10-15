///|
test "clipboard output takes precedence over raw in either flag order" {
  for
    args in [
      ["command", "--raw", "--copy"],
      ["command", "--copy", "--raw"],
      [
        "command", "--raw", "claude", "--copy", "seed", "--api-format", "anthropic",
      ],
      [
        "command", "--copy", "claude", "--raw", "seed", "--api-format", "anthropic",
      ],
      ["command", "--copy", "--raw", "--raw", "--copy"],
    ] {
    match @command.parse_args(args) {
      TemporaryCommand(agent~, provider~, api_format~, output~) => {
        assert_true(output is Clipboard)
        if args.contains("claude") {
          assert_eq(agent, Some("claude"))
          assert_eq(provider, Some("seed"))
          assert_true(api_format is Some(@agent.Anthropic))
        } else {
          assert_true(agent is None)
          assert_true(provider is None)
          assert_true(api_format is None)
        }
      }
      _ => fail("Expected clipboard command output")
    }
  }
}
