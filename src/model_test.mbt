///|
test "limits reject invalid configurations" {
  validate_options(options(1))
  validate_constraints(constraints())
  let failed = try {
    validate_options(options(0))
    false
  } catch {
    _ => true
  }
  assert_true(failed)
  let negative = try {
    validate_constraints(constraints(max_gap=-1))
    false
  } catch {
    _ => true
  }
  assert_true(negative)
}
