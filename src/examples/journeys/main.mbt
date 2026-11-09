// Synthetic journeys: a customer record contains ordered baskets of actions.

///|
fn main raise {
  let (db, labels) = @seq.encode_labeled_sequences([
    [["browse", "search"], ["cart"], ["pay"]],
    [["browse"], ["cart"], ["pay"]],
    [["browse", "search"], ["cart"]],
    [["search"], ["leave"]],
  ])
  let found = @seq.mine(db, @seq.options(2, max_items=3))
  let target = @seq.pattern([[0], [2]])
  assert_eq(@seq.support(db, target), 3)
  for record in @seq.closed_patterns(found) {
    let names = record.pattern.itemsets.map(fn(event) {
      event.map(fn(id) { @seq.label_of(labels, id).unwrap_or("?") }).join("+")
    })
    println("\{names.join(" -> ")} : \{record.support}/4")
  }
}
