///|
fn filter_record(
  events : Array[Array[Int32]],
  count : Int32,
) -> FrequentPattern raise MiningError {
  { pattern: pattern(events), support: count, }
}

///|
test "filter uses strict superpatterns and preserves support distinctions" {
  let a = filter_record([[1]], 3)
  let b = filter_record([[1], [2]], 2)
  let c = filter_record([[1], [2], [3]], 2)
  let d = filter_record([[9]], 1)
  let family = [b, d, a, c, b]
  let closed = closed_patterns(family)
  let maximal = maximal_patterns(family)
  assert_eq(closed.length(), 3)
  assert_true(closed.contains(a))
  assert_true(closed.contains(c))
  assert_true(closed.contains(d))
  assert_eq(maximal.length(), 2)
  assert_true(maximal.contains(c))
  assert_true(maximal.contains(d))
  assert_eq(closed, closed_patterns([c, b, a, d]))
  assert_eq(maximal, maximal_patterns([d, a, b, c]))
}

///|
test "filter distinguishes itemset inclusion from event order" {
  let small = filter_record([[1]], 2)
  let together = filter_record([[1, 2]], 2)
  let forward = filter_record([[1], [2]], 2)
  let reverse = filter_record([[2], [1]], 2)
  let result = maximal_patterns([small, together, forward, reverse])
  assert_eq(result.length(), 3)
  assert_true(result.contains(together))
  assert_true(result.contains(forward))
  assert_true(result.contains(reverse))
  assert_eq(closed_patterns([small, together]).length(), 1)
}

///|
test "filter defines closure only inside the supplied bounded family" {
  let bounded = filter_record([[1]], 2)
  assert_eq(closed_patterns([bounded]), [bounded])
  assert_eq(maximal_patterns([bounded]), [bounded])
  assert_eq(closed_patterns([]), [])
  assert_eq(maximal_patterns([]), [])
}

///|
test "filter validates all records and rejects duplicate support conflicts" {
  let good = filter_record([[1]], 2)
  let conflict = filter_record([[1]], 1)
  let zero = filter_record([[2]], 0)
  let negative = filter_record([[3]], -1)
  let malformed : FrequentPattern = {
    pattern: { itemsets: [[2, 1]], },
    support: 1,
  }
  let empty : FrequentPattern = { pattern: { itemsets: [], }, support: 1, }
  for family in [[good, conflict], [zero], [negative], [malformed], [empty]] {
    let closed_failed = try {
      ignore(closed_patterns(family))
      false
    } catch {
      Invalid(_) => true
      _ => false
    }
    let maximal_failed = try {
      ignore(maximal_patterns(family))
      false
    } catch {
      Invalid(_) => true
      _ => false
    }
    assert_true(closed_failed)
    assert_true(maximal_failed)
  }
}

///|
test "filter copies outer and inner arrays for both public operations" {
  let input = filter_record([[1], [2, 3]], 2)
  let closed = closed_patterns([input, input])
  let maximal = maximal_patterns([input])
  assert_eq(closed.length(), 1)
  closed[0].pattern.itemsets[1][0] = 8
  closed[0].pattern.itemsets.push([9])
  assert_eq(input.pattern.itemsets, [[1], [2, 3]])
  assert_eq(maximal[0].pattern.itemsets, [[1], [2, 3]])
  input.pattern.itemsets[0][0] = 7
  assert_eq(maximal[0].pattern.itemsets, [[1], [2, 3]])
}
