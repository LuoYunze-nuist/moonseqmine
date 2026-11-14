// Synthetic journeys: a customer record contains ordered baskets of actions.

///|
fn main raise {
  let (db, labels) = @seq.encode_labeled_sequences([
    [["browse", "search"], ["cart"], ["pay"]],
    [["browse"], ["cart"], ["pay"]],
    [["browse", "search"], ["cart"]],
    [["search"], ["leave"]],
  ])
  let ranked = @seq.top_k(db, 4, max_items=3)
  let target = @seq.pattern([[0], [2]])
  assert_eq(@seq.supporting_ids(db, target), [0, 1, 2])
  assert_true(
    ranked.any(fn(record) {
      @seq.pattern_key(record.pattern) == "0;2" && record.support == 3
    }),
  )
  for record in ranked {
    let names = record.pattern.itemsets.map(fn(event) {
      event.map(fn(id) { @seq.label_of(labels, id).unwrap_or("?") }).join("+")
    })
    println("\{names.join(" -> ")} : \{record.support}/4")
  }
}
