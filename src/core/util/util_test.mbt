///|
test "is_blank returns true for empty string" {
  assert_true(@util.is_blank(""))
}

///|
test "is_blank returns true for whitespace only" {
  assert_true(@util.is_blank("   "))
  assert_true(@util.is_blank("\t"))
  assert_true(@util.is_blank(" \t \n "))
}

///|
test "is_blank returns false for non-blank string" {
  assert_false(@util.is_blank("hello"))
  assert_false(@util.is_blank("  hello  "))
}
