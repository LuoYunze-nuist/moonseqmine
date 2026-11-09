// Integer SPMF input represents service event batches within each request.

///|
fn main raise {
  let db = @seq.parse_spmf(
    "1 -1 2 3 -1 4 -1 -2\n1 -1 2 -1 4 -1 -2\n1 -1 9 -1 4 -1 -2\n",
  )
  let c = @seq.constraints(max_gap=0)
  let found = @seq.mine(db, @seq.options(2, max_items=3), constraints=c)
  let p = @seq.pattern([[1], [2], [4]])
  let evidence = @seq.witnesses(db, p, constraints=c)
  assert_eq(evidence.length(), 2)
  for w in evidence {
    assert_true(@seq.verify_witness(db, p, w, constraints=c))
  }
  let (success, retry) = @seq.partition_database(db, [0, 1])
  let comparisons = @seq.compare_cohorts(
    success.database,
    retry.database,
    [p],
    constraints=c,
  )
  assert_eq(comparisons[0].foreground_support, 2)
  println(
    "adjacent patterns=\{found.length()}, complete embeddings=\{evidence.length()}",
  )
  println(@seq.format_spmf(db))
}
