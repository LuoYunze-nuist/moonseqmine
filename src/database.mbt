///|
/// Validate canonical input without silently sorting an invalid public value.
pub fn validate_pattern(p : Pattern) -> Unit raise MiningError {
  if p.itemsets.is_empty() {
    raise Invalid("pattern must contain an itemset")
  }
  validate_sequence(p.itemsets)
}

///|
fn validate_sequence(seq : Array[Array[Int32]]) -> Unit raise MiningError {
  for event in seq {
    if event.is_empty() {
      raise Invalid("empty itemsets are not allowed")
    }
    let mut previous = -1
    for item in event {
      if item < 0 || item <= previous {
        raise Invalid("itemsets must contain sorted distinct nonnegative IDs")
      }
      previous = item
    }
  }
}

///|
pub fn validate_database(db : Database) -> Unit raise MiningError {
  for seq in db.sequences {
    validate_sequence(seq)
  }
}

///|
fn canonical_sequence(
  seq : Array[Array[Int32]],
) -> Array[Array[Int32]] raise MiningError {
  let out : Array[Array[Int32]] = []
  for event in seq {
    if event.is_empty() {
      raise Invalid("empty itemsets are not allowed")
    }
    let items = event.copy()
    items.sort()
    let unique : Array[Int32] = []
    for item in items {
      if item < 0 {
        raise Invalid("item IDs must be nonnegative")
      }
      if unique.is_empty() || unique[unique.length() - 1] != item {
        unique.push(item)
      }
    }
    out.push(unique)
  }
  out
}

///|
/// Copy input and canonicalize each itemset. Sequence order is preserved.
pub fn pattern(itemsets : Array[Array[Int32]]) -> Pattern raise MiningError {
  if itemsets.is_empty() {
    raise Invalid("empty pattern")
  }
  { itemsets: canonical_sequence(itemsets), }
}

///|
/// Empty databases and empty sequences are permitted, but empty itemsets are not.
pub fn database(
  sequences : Array[Array[Array[Int32]]],
) -> Database raise MiningError {
  let out = []
  for seq in sequences {
    out.push(canonical_sequence(seq))
  }
  { sequences: out, }
}

///|
pub fn item_count(p : Pattern) -> Int32 {
  let mut total = 0
  for event in p.itemsets {
    total += event.length()
  }
  total
}

///|
/// Stable structural key, distinct from any human label spelling.
pub fn pattern_key(p : Pattern) -> String {
  let events = p.itemsets.map(fn(event) {
    event.map(fn(item) { item.to_string() }).join(",")
  })
  events.join(";")
}
