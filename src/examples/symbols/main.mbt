// Toy symbolic records: gaps are allowed; this is not biological alignment.

///|
fn main raise {
  let (db, labels) = @seq.encode_labeled_sequences([
    [["A"], ["C"], ["G"], ["T"]],
    [["A"], ["G"], ["T"]],
    [["C"], ["G"], ["A"]],
  ])
  let json = @seq.format_database_json(db)
  let round_trip = @seq.parse_database_json(json)
  assert_eq(round_trip, db)
  let frequent = @seq.mine(db, @seq.options(2, max_items=3))
  let index = @seq.support_index(db)
  let ag = @seq.pattern([[0], [2]])
  assert_eq(index.query_ids(ag), [0, 1])
  let rules = @seq.sequential_rules(db, frequent, min_confidence=0.5)
  assert_true(rules.length() > 0)
  let (foreground, background) = @seq.partition_database(db, [0, 1])
  let comparisons = @seq.compare_cohorts(
    foreground.database,
    background.database,
    [ag],
  )
  assert_eq(comparisons[0].foreground_support, 2)
  println(
    "frequent symbolic patterns=\{frequent.length()}, rules=\{rules.length()}, " +
    "foreground support=\{comparisons[0].foreground_support}",
  )
  for record in @seq.maximal_patterns(frequent) {
    let names = record.pattern.itemsets.map(fn(event) {
      event.map(fn(id) { @seq.label_of(labels, id).unwrap_or("?") }).join("+")
    })
    println("\{names.join(" -> ")} : \{record.support}")
  }
}
