///|
test "query results cannot mutate index postings" {
  let index = @moonseqmine.support_index(
    @moonseqmine.database([[[1]], [[1], [2]]]),
  )
  let p = @moonseqmine.pattern([[1]])
  let ids = index.query_ids(p)
  ids[0] = 99
  ids.push(77)
  assert_eq(index.query_ids(p), [0, 1])
  assert_eq(index.query_support(p), 2)
}
