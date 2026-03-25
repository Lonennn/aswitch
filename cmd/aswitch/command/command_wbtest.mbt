///|
test "parse_args maps providers and legacy aliases to list providers" {
  assert_true(parse_args(["providers"]) is ListProviders)
  assert_true(parse_args(["list"]) is ListProviders)
  assert_true(parse_args(["ls"]) is ListProviders)
}

///|
test "parse_args maps agents to list agents" {
  assert_true(parse_args(["agents"]) is ListAgents)
}
