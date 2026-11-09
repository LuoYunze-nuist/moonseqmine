///|
test "itemset inclusion differs from unordered baskets" {
  let db = database([[[1, 2], [3]], [[1], [2], [3]], [[3], [1, 2]], []])
  assert_eq(supporting_ids(db, pattern([[1, 2], [3]])), [0])
  assert_eq(support(db, pattern([[1], [3]])), 2)
  assert_true(is_subpattern(pattern([[1], [3]]), pattern([[1, 2], [2], [3]])))
}

///|
test "gap matching must retain later starts" {
  let db = database([[[1], [9], [1], [2]], [[1], [9], [2]]])
  let p = pattern([[1], [2]])
  assert_eq(supporting_ids(db, p, constraints=constraints(max_gap=0)), [0])
  assert_eq(support(db, p, constraints=constraints(max_span=1)), 1)
  let limited = try {
    let _ = support(db, p, max_steps=1)
    false
  } catch {
    Resource(_) => true
    _ => false
  }
  assert_true(limited)
}
