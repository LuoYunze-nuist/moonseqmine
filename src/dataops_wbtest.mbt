///|
test "cohort selections carry source IDs and do not duplicate weight" {
  let db = database([[[1]], [], [[2], [2]]])
  let (a, b) = partition_database(db, [2, 0])
  assert_eq(a.source_ids, [2, 0])
  assert_eq(b.source_ids, [1])
  a.database.sequences[0][0][0] = 3
  assert_eq(db.sequences[2][0], [2])
  let bad = try {
    let _ = select_sequences(db, [0, 0])
    false
  } catch {
    _ => true
  }
  assert_true(bad)
}

///|
test "exact relative threshold and summary distinguish occurrences" {
  assert_eq(relative_min_support(3, 1, 2), 2)
  assert_eq(
    relative_min_support(2147483647, 2147483647, 2147483647),
    2147483647,
  )
  assert_eq(relative_min_support(0, 1, 2), 0)
  let s = summarize_database(database([[[1, 2], [1]], [], [[2]]]))
  assert_eq(s.events, 3L)
  assert_eq(s.items, 4L)
  assert_eq(s.empty_sequences, 1)
  assert_eq(s.alphabet[0], ItemFrequency::{
    item: 1,
    sequence_support: 1,
    event_occurrences: 2,
  })
}
