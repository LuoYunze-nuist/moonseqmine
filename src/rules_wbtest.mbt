///|
test "rules recompute sequence support confidence and lift" {
  let db = database([[[1], [2]], [[1], [1], [2]], [[1]], [[2]]])
  let full : FrequentPattern = { pattern: pattern([[1], [2]]), support: 2, }
  let rules = sequential_rules(db, [full])
  assert_eq(rules.length(), 1)
  let rule = rules[0]
  assert_eq(rule.prefix, pattern([[1]]))
  assert_eq(rule.suffix, pattern([[2]]))
  assert_eq(rule.support, 2)
  assert_eq(rule.prefix_support, 3)
  assert_eq(rule.suffix_support, 3)
  assert_eq(rule.database_size, 4)
  assert_eq(rule.confidence, 2.0 / 3.0)
  assert_eq(rule.lift, 2.0 / 3.0 / 0.75)
  assert_eq(sequential_rules(db, [full], min_confidence=0.67), [])
  assert_eq(sequential_rules(db, [full], min_confidence=2.0 / 3.0), rules)
}

///|
test "rules split at every itemset boundary and preserve multi-item events" {
  let db = database([[[1, 2], [3], [4, 5]], [[1, 2], [3]], [[3], [4, 5]], []])
  let p = pattern([[1, 2], [3], [4, 5]])
  let record : FrequentPattern = { pattern: p, support: 1, }
  let rules = sequential_rules(db, [record, record], min_confidence=0.5)
  assert_eq(rules.length(), 2)
  assert_eq(rules[0].prefix.itemsets, [[1, 2]])
  assert_eq(rules[0].suffix.itemsets, [[3], [4, 5]])
  assert_eq(rules[1].prefix.itemsets, [[1, 2], [3]])
  assert_eq(rules[1].suffix.itemsets, [[4, 5]])
  for rule in rules {
    assert_eq(rule.confidence, 0.5)
    assert_eq(rule.lift, 1.0)
  }
  rules[0].prefix.itemsets[0][0] = 9
  rules[0].suffix.itemsets[1][0] = 9
  assert_eq(p.itemsets, [[1, 2], [3], [4, 5]])
  assert_eq(rules[1].prefix.itemsets, [[1, 2], [3]])
  assert_eq(rules[1].suffix.itemsets, [[4, 5]])
}

///|
test "rules validate support even for unsplittable or confidence-filtered input" {
  let db = database([[[1, 2], [3]], [[1, 2]]])
  let stale : FrequentPattern = { pattern: pattern([[1, 2], [3]]), support: 2, }
  let single_stale : FrequentPattern = {
    pattern: pattern([[1, 2]]),
    support: 1,
  }
  let absent : FrequentPattern = { pattern: pattern([[9], [8]]), support: 1, }
  for record in [stale, single_stale, absent] {
    let failed = try {
      ignore(sequential_rules(db, [record], min_confidence=1.0))
      false
    } catch {
      Invalid(_) => true
      _ => false
    }
    assert_true(failed)
  }
  let single : FrequentPattern = { pattern: pattern([[1, 2]]), support: 2, }
  assert_eq(sequential_rules(db, [single]), [])
}

///|
test "rules reject nonfinite and out of range confidence even on empty data" {
  let empty = database([])
  for threshold in [0.0 / 0.0, 1.0 / 0.0, -1.0 / 0.0, -0.01, 1.01] {
    let failed = try {
      ignore(sequential_rules(empty, [], min_confidence=threshold))
      false
    } catch {
      Invalid(_) => true
      _ => false
    }
    assert_true(failed)
  }
  assert_eq(sequential_rules(empty, [], min_confidence=0.0), [])
  assert_eq(sequential_rules(empty, [], min_confidence=1.0), [])
  let valid : FrequentPattern = { pattern: pattern([[1], [2]]), support: 1, }
  assert_eq(sequential_rules(empty, [valid]), [])
}

///|
test "rules reject malformed input and conflicting duplicate support" {
  let db = database([[[1], [2]]])
  let good : FrequentPattern = { pattern: pattern([[1], [2]]), support: 1, }
  let conflict : FrequentPattern = { pattern: good.pattern, support: 2, }
  let zero : FrequentPattern = { pattern: good.pattern, support: 0, }
  let bad : FrequentPattern = { pattern: { itemsets: [[2, 1]], }, support: 1, }
  for family in [[good, conflict], [zero], [bad]] {
    let failed = try {
      ignore(sequential_rules(db, family))
      false
    } catch {
      Invalid(_) => true
      _ => false
    }
    assert_true(failed)
  }
  let malformed_db : Database = { sequences: [[[]]], }
  let database_failed = try {
    ignore(sequential_rules(malformed_db, []))
    false
  } catch {
    Invalid(_) => true
    _ => false
  }
  assert_true(database_failed)
}

///|
test "rules are ordered deterministically and use unconstrained support" {
  let db = database([[[1], [9], [2]], [[1], [2]], [[2], [1]]])
  let forward : FrequentPattern = { pattern: pattern([[1], [2]]), support: 2, }
  let reverse : FrequentPattern = { pattern: pattern([[2], [1]]), support: 1, }
  let rules = sequential_rules(db, [reverse, forward])
  assert_eq(rules, sequential_rules(db, [forward, reverse, forward]))
  assert_eq(rules[0].support, 2)
  assert_eq(rules[0].prefix, pattern([[1]]))
  let constrained_count = support(
    db,
    forward.pattern,
    constraints=constraints(max_gap=0),
  )
  assert_eq(constrained_count, 1)
  let constrained_record : FrequentPattern = {
    pattern: forward.pattern,
    support: constrained_count,
  }
  let failed = try {
    ignore(sequential_rules(db, [constrained_record]))
    false
  } catch {
    Invalid(_) => true
    _ => false
  }
  assert_true(failed)
}
