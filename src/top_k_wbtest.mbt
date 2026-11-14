///|
test "top_k returns stable exact ranking with support ties" {
  let db = database([[[1], [2], [3]], [[1], [2]], [[1], [3]], [[2], [3]]])
  let found = top_k(db, 4, max_items=2)
  assert_eq(found.length(), 4)
  assert_eq(
    found.map(fn(record) { (pattern_key(record.pattern), record.support) }),
    [("1", 3), ("2", 3), ("3", 3), ("1;2", 2)],
  )
}

///|
test "top_k returns every available pattern when k is larger" {
  let db = database([[[1], [2]], [[1]], []])
  let found = top_k(db, 99, max_items=2)
  assert_eq(found, [
    { pattern: pattern([[1]]), support: 2, },
    { pattern: pattern([[2]]), support: 1, },
    { pattern: pattern([[1], [2]]), support: 1, },
  ])
}

///|
test "top_k rejects nonpositive k and invalid budgets" {
  let db = database([[[1]]])
  for k in [0, -1] {
    let failed = try {
      ignore(top_k(db, k))
      false
    } catch {
      Invalid(_) => true
      _ => false
    }
    assert_true(failed)
  }
  let failed = try {
    ignore(top_k(db, 1, max_items=0))
    false
  } catch {
    Invalid(_) => true
    _ => false
  }
  assert_true(failed)
  for invalid in [(65, 1000000, 10000000), (8, 0, 10000000), (8, 1000000, 0)] {
    let failed = try {
      ignore(
        top_k(
          db,
          1,
          max_items=invalid.0,
          max_states=invalid.1,
          max_steps=invalid.2,
        ),
      )
      false
    } catch {
      Invalid(_) => true
      _ => false
    }
    assert_true(failed)
  }
}

///|
test "top_k agrees with an independent powerset oracle" {
  let db = database([[[1, 2], [3]], [[1], [2, 3]], [[1, 3], [2]], [[2], [3]]])
  let expected : Array[(String, Int32)] = []
  for key, support in brute_counts(db, 3, constraints()) {
    expected.push((key, support))
  }
  expected.sort_by(fn(a, b) {
    let support_order = b.1.compare(a.1)
    if support_order != 0 {
      support_order
    } else {
      a.0.compare(b.0)
    }
  })
  for k in [1, 2, 5, 10] {
    let actual = top_k(db, k, max_items=3)
    assert_eq(actual.length(), k)
    for i = 0; i < actual.length(); i = i + 1 {
      assert_eq(
        (pattern_key(actual[i].pattern), actual[i].support),
        expected[i],
      )
    }
  }
}
