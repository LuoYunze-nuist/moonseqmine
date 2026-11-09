///|
test "cohort comparison counts sequences and includes empty samples" {
  let fg = database([[[1], [2]], [[1, 2]], [], [[1], [2]]])
  let bg = database([[[1], [2]], [], [], []])
  let p = pattern([[1], [2]])
  let q = pattern([[1]])
  let result = compare_cohorts(fg, bg, [p, q])
  let row = result[0]
  assert_eq(row.pattern, p)
  assert_eq(row.foreground_support, 2)
  assert_eq(row.background_support, 1)
  assert_eq(row.foreground_size, 4)
  assert_eq(row.background_size, 4)
  assert_eq(row.foreground_rate, 0.5)
  assert_eq(row.background_rate, 0.25)
  assert_eq(row.difference, 0.25)
  assert_eq(row.ratio, Some(2.0))
  assert_eq(result[1].pattern, q)
  assert_eq(result[1].foreground_support, 3)
}

///|
test "cohort empty queues have zero rates and absent zero-background ratio" {
  let empty = database([])
  let populated = database([[[1]], [[1]]])
  let p = pattern([[1]])
  let both = compare_cohorts(empty, empty, [p])[0]
  assert_eq(both.foreground_size, 0)
  assert_eq(both.background_size, 0)
  assert_eq(both.foreground_rate, 0.0)
  assert_eq(both.background_rate, 0.0)
  assert_eq(both.difference, 0.0)
  assert_eq(both.ratio, None)
  let no_background = compare_cohorts(populated, empty, [p])[0]
  assert_eq(no_background.difference, 1.0)
  assert_eq(no_background.ratio, None)
  let no_foreground = compare_cohorts(empty, populated, [p])[0]
  assert_eq(no_foreground.difference, -1.0)
  assert_eq(no_foreground.ratio, Some(0.0))
  let absent = compare_cohorts(populated, populated, [pattern([[9]])])[0]
  assert_eq(absent.ratio, None)
  assert_eq(compare_cohorts(empty, empty, []), [])
}

///|
test "cohort applies identical constraints and produces independent copies" {
  let fg = database([[[1], [9], [2]]])
  let bg = database([[[1], [2]]])
  let p = pattern([[1], [2]])
  let rows = compare_cohorts(fg, bg, [p, p], constraints=constraints(max_gap=0))
  assert_eq(rows[0].foreground_support, 0)
  assert_eq(rows[0].background_support, 1)
  assert_eq(rows[0].ratio, Some(0.0))
  rows[0].pattern.itemsets[0][0] = 8
  rows[0].pattern.itemsets.push([3])
  assert_eq(rows[1].pattern, p)
  assert_eq(p.itemsets, [[1], [2]])
}

///|
test "cohort validates inputs and limits even without pattern queries" {
  let empty = database([])
  for limits in [constraints(max_gap=-1), constraints(max_span=-1)] {
    let failed = try {
      ignore(compare_cohorts(empty, empty, [], constraints=limits))
      false
    } catch {
      Invalid(_) => true
      _ => false
    }
    assert_true(failed)
  }
  let budget_failed = try {
    ignore(compare_cohorts(empty, empty, [], max_steps=0))
    false
  } catch {
    Invalid(_) => true
    _ => false
  }
  assert_true(budget_failed)
  let bad : Database = { sequences: [[[2, 1]]], }
  for pair in [(bad, empty), (empty, bad)] {
    let failed = try {
      ignore(compare_cohorts(pair.0, pair.1, []))
      false
    } catch {
      Invalid(_) => true
      _ => false
    }
    assert_true(failed)
  }
  let malformed : Pattern = { itemsets: [[]], }
  let pattern_failed = try {
    ignore(compare_cohorts(empty, empty, [malformed]))
    false
  } catch {
    Invalid(_) => true
    _ => false
  }
  assert_true(pattern_failed)
}

///|
test "cohort propagates exhausted support budgets" {
  let db = database([[[1], [2]]])
  let failed = try {
    ignore(compare_cohorts(db, db, [pattern([[1], [2]])], max_steps=1))
    false
  } catch {
    Resource(_) => true
    _ => false
  }
  assert_true(failed)
}
