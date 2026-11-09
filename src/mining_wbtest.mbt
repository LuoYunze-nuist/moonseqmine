///|
test "I and S extensions count sequences instead of occurrences" {
  let db = database([[[1, 2], [1], [3]], [[1, 2], [3]], [[2], [3]], []])
  let result = mine_with_stats(db, options(2, max_items=3))
  let counts : Map[String, Int32] = Map([])
  for found in result.patterns {
    counts[pattern_key(found.pattern)] = found.support
    assert_eq(found.support, support(db, found.pattern))
  }
  assert_eq(counts.get("1,2;3"), Some(2))
  assert_eq(counts.get("1;1"), None)
  assert_eq(counts.get("2;3"), Some(3))
  assert_eq(result.stats.emitted_patterns, result.patterns.length())
}

///|
test "mining budgets raise instead of truncating" {
  let db = database([[[1, 2], [3]]])
  let pattern_limit = try {
    let _ = mine(db, options(1, max_patterns=1))
    false
  } catch {
    Resource(_) => true
    _ => false
  }
  let state_limit = try {
    let _ = mine(db, options(1, max_states=1))
    false
  } catch {
    Resource(_) => true
    _ => false
  }
  let work_limit = try {
    let _ = mine(db, options(1, max_steps=1))
    false
  } catch {
    Resource(_) => true
    _ => false
  }
  assert_true(pattern_limit && state_limit && work_limit)
  assert_eq(mine(db, options(2)), [])
}

///|
test "constrained projections preserve later first and last positions" {
  let db = database([[[1], [9], [1, 2], [3]], [[1, 2], [3]]])
  let c = constraints(max_gap=0, max_span=1)
  for found in mine(db, options(2, max_items=3), constraints=c) {
    assert_eq(found.support, support(db, found.pattern, constraints=c))
  }
  let found = mine(db, options(2, max_items=3), constraints=c)
  assert_true(found.any(fn(p) { pattern_key(p.pattern) == "1,2;3" }))
}
