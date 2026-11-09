///|
/// Sorted subset test; no allocations and no dependence on label magnitudes.
fn contains_itemset(haystack : Array[Int32], needle : Array[Int32]) -> Bool {
  let mut i = 0
  let mut j = 0
  while i < haystack.length() && j < needle.length() {
    if haystack[i] < needle[j] {
      i += 1
    } else if haystack[i] == needle[j] {
      i += 1
      j += 1
    } else {
      return false
    }
  }
  j == needle.length()
}

///|
/// Subsequence order with itemset inclusion; no positional constraints.
pub fn is_subpattern(
  small : Pattern,
  large : Pattern,
) -> Bool raise MiningError {
  validate_pattern(small)
  validate_pattern(large)
  let mut cursor = 0
  for event in large.itemsets {
    if contains_itemset(event, small.itemsets[cursor]) {
      cursor += 1
      if cursor == small.itemsets.length() {
        return true
      }
    }
  }
  false
}

///|
priv struct WorkBudget {
  mut steps : Int32
  limit : Int32
}

///|
fn WorkBudget::tick(self : WorkBudget) -> Unit raise MiningError {
  if self.steps >= self.limit {
    raise Resource("work budget exceeded")
  }
  self.steps += 1
}

///|
fn check_step_limit(n : Int32) -> Unit raise MiningError {
  if n < 1 {
    raise Invalid("max_steps must be positive")
  }
}

///|
fn position_allowed(
  first : Int32,
  last : Int32,
  pos : Int32,
  c : Constraints,
) -> Bool {
  if last < 0 {
    return true
  }
  if c.max_gap is Some(gap) && pos - last - 1 > gap {
    return false
  }
  if c.max_span is Some(span) && pos - first > span {
    return false
  }
  true
}

///|
/// Keep all first/end pairs: earliest-only projections are wrong under max_gap.
fn sequence_matches(
  seq : Array[Array[Int32]],
  p : Pattern,
  c : Constraints,
  budget : WorkBudget,
) -> Bool raise MiningError {
  let mut states : Array[(Int32, Int32)] = [(-1, -1)]
  for event in p.itemsets {
    let next : Array[(Int32, Int32)] = []
    let seen : Set[(Int32, Int32)] = Set([])
    for state in states {
      let (first, last) = state
      for pos = last + 1; pos < seq.length(); pos = pos + 1 {
        budget.tick()
        if !position_allowed(first, last, pos, c) {
          break
        }
        if contains_itemset(seq[pos], event) {
          let start = if first < 0 { pos } else { first }
          let pair = (start, pos)
          if !seen.contains(pair) {
            seen.add(pair)
            next.push(pair)
          }
        }
      }
    }
    if next.is_empty() {
      return false
    }
    states = next
  }
  !states.is_empty()
}

///|
/// Sorted sequence IDs. Each input record contributes at most once.
pub fn supporting_ids(
  db : Database,
  p : Pattern,
  constraints~ : Constraints = constraints(),
  max_steps~ : Int32 = 10000000,
) -> Array[Int32] raise MiningError {
  validate_database(db)
  validate_pattern(p)
  validate_constraints(constraints)
  check_step_limit(max_steps)
  let budget = WorkBudget::{ steps: 0, limit: max_steps, }
  let out = []
  for sid = 0; sid < db.sequences.length(); sid = sid + 1 {
    if sequence_matches(db.sequences[sid], p, constraints, budget) {
      out.push(sid)
    }
  }
  out
}

///|
pub fn support(
  db : Database,
  p : Pattern,
  constraints~ : Constraints = constraints(),
  max_steps~ : Int32 = 10000000,
) -> Int32 raise MiningError {
  supporting_ids(db, p, constraints~, max_steps~).length()
}
