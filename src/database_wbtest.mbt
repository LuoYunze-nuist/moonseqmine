///|
test "canonicalization isolates nested input and preserves event order" {
  let input = [[3, 1, 3], [2]]
  let p = pattern(input)
  assert_eq(p.itemsets, [[1, 3], [2]])
  input[0][0] = 8
  assert_eq(p.itemsets, [[1, 3], [2]])
  assert_eq(item_count(p), 3)
  assert_eq(pattern_key(p), "1,3;2")
  assert_eq(database([[]]).sequences.length(), 1)
  let bad = try {
    validate_database({ sequences: [[[2, 1]]], })
    false
  } catch {
    _ => true
  }
  assert_true(bad)
}
