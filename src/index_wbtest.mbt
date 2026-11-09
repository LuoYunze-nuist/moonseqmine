///|
test "indexed queries retain exact order and isolated source snapshot" {
  let db = database([[[1, 2], [3]], [[1], [2], [3]], [[3], [1, 2]], []])
  let index = support_index(db)
  let patterns = [
    pattern([[1, 2]]),
    pattern([[1], [2]]),
    pattern([[1], [3]]),
    pattern([[9]]),
  ]
  assert_eq(index.sequence_count(), 4)
  for p in patterns {
    for c in [constraints(), constraints(max_gap=0), constraints(max_span=1)] {
      assert_eq(
        index.query_ids(p, constraints=c),
        supporting_ids(db, p, constraints=c),
      )
    }
  }
  db.sequences[0][0][0] = 99
  assert_eq(index.query_ids(pattern([[1, 2], [3]])), [0])
  assert_eq(index.query_support(pattern([[1]])), 3)
}
