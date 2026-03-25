///|
test "supported_agents returns canonical agent names" {
  assert_eq(supported_agents(), ["claude-code", "open-code", "openclaw"])
}
