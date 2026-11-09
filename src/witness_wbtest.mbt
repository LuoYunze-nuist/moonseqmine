///|
test "witnesses retain all embeddings but support counts records" {
  let db = database([[[1], [1], [2], [2]]])
  let p = pattern([[1], [2]])
  let found = witnesses(db, p)
  assert_eq(found.length(), 4)
  assert_eq(support(db, p), 1)
  for w in found {
    assert_true(verify_witness(db, p, w))
  }
  assert_eq(witnesses(db, p, constraints=constraints(max_gap=0)).length(), 1)
  assert_false(verify_witness(db, p, { sequence_id: 0, positions: [2, 1], }))
  let limited = try {
    let _ = witnesses(db, p, max_witnesses=3)
    false
  } catch {
    Resource(_) => true
    _ => false
  }
  assert_true(limited)
}
