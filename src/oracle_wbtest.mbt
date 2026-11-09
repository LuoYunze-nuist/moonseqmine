// Independent oracle: enumerate source position masks and all nonempty item
// subsets, rather than growing prefixes or calling the production matcher.

///|
fn oracle_event_choices(event : Array[Int32]) -> Array[Array[Int32]] {
  let out = []
  for mask = 1; mask < 1 << event.length(); mask = mask + 1 {
    let choice = []
    for bit = 0; bit < event.length(); bit = bit + 1 {
      if (mask & (1 << bit)) != 0 {
        choice.push(event[bit])
      }
    }
    out.push(choice)
  }
  out
}

///|
fn oracle_product(
  events : Array[Array[Int32]],
  at : Int32,
  built : Array[Array[Int32]],
  max_items : Int32,
  keys : Set[String],
) -> Unit {
  if at == events.length() {
    let p = Pattern::{ itemsets: built, }
    if item_count(p) <= max_items {
      keys.add(pattern_key(p))
    }
    return
  }
  for choice in oracle_event_choices(events[at]) {
    built.push(choice)
    oracle_product(events, at + 1, built, max_items, keys)
    let _ = built.pop()
  }
}

///|
fn brute_counts(
  db : Database,
  max_items : Int32,
  c : Constraints,
) -> Map[String, Int32] {
  let counts : Map[String, Int32] = Map([])
  for seq in db.sequences {
    let keys : Set[String] = Set([])
    for mask = 1; mask < 1 << seq.length(); mask = mask + 1 {
      let positions : Array[Int32] = []
      let events = []
      for pos = 0; pos < seq.length(); pos = pos + 1 {
        if (mask & (1 << pos)) != 0 {
          positions.push(pos)
          events.push(seq[pos])
        }
      }
      let mut allowed = true
      if c.max_span is Some(span) &&
        positions[positions.length() - 1] - positions[0] > span {
        allowed = false
      }
      for i = 1; i < positions.length(); i = i + 1 {
        if c.max_gap is Some(gap) && positions[i] - positions[i - 1] - 1 > gap {
          allowed = false
        }
      }
      if allowed {
        oracle_product(events, 0, [], max_items, keys)
      }
    }
    for key in keys {
      counts[key] = counts.get(key).unwrap_or(0) + 1
    }
  }
  counts
}

///|
test "864 bounded databases agree with independent source powerset oracle" {
  let settings = [
    constraints(),
    constraints(max_gap=0),
    constraints(max_span=1),
    constraints(max_gap=1, max_span=2),
  ]
  for seed = 0; seed < 72; seed = seed + 1 {
    let sequences = []
    let mut state = seed + 1
    for sid = 0; sid < 3; sid = sid + 1 {
      let seq = []
      state = (state * 73 + 19) % 997
      let len = state % 5
      for pos = 0; pos < len; pos = pos + 1 {
        state = (state * 73 + 19) % 997
        let mask = state % 7 + 1
        let event = []
        for item = 0; item < 3; item = item + 1 {
          if (mask & (1 << item)) != 0 {
            event.push(item)
          }
        }
        seq.push(event)
      }
      sequences.push(seq)
    }
    let db = database(sequences)
    for c in settings {
      let expected = brute_counts(db, 4, c)
      for minimum = 1; minimum <= 3; minimum = minimum + 1 {
        let actual = mine(db, options(minimum, max_items=4), constraints=c)
        let actual_map : Map[String, Int32] = Map([])
        for found in actual {
          actual_map[pattern_key(found.pattern)] = found.support
        }
        let filtered : Map[String, Int32] = Map([])
        for key, value in expected {
          if value >= minimum {
            filtered[key] = value
          }
        }
        assert_eq(actual_map, filtered)
      }
    }
  }
}
