///|
/// Immutable-by-API snapshot with item-to-sequence postings for repeated queries.
pub struct SupportIndex {
  priv snapshot : Database
  priv postings : Map[Int32, Array[Int32]]
}

///|
/// Snapshot the input, collecting one posting per item per sequence.
pub fn support_index(db : Database) -> SupportIndex raise MiningError {
  validate_database(db)
  let snapshot = database(db.sequences)
  let postings : Map[Int32, Array[Int32]] = Map([])
  for sid = 0; sid < snapshot.sequences.length(); sid = sid + 1 {
    let seen : Set[Int32] = Set([])
    for event in snapshot.sequences[sid] {
      for item in event {
        if seen.contains(item) {
          continue
        }
        seen.add(item)
        postings.get_or_init(item, fn() { [] }).push(sid)
      }
    }
  }
  { snapshot, postings, }
}

///|
pub fn SupportIndex::sequence_count(self : SupportIndex) -> Int32 {
  self.snapshot.sequences.length()
}

///|
fn intersect_ids(left : Array[Int32], right : Array[Int32]) -> Array[Int32] {
  let result = []
  let mut i = 0
  let mut j = 0
  while i < left.length() && j < right.length() {
    if left[i] == right[j] {
      result.push(left[i])
      i += 1
      j += 1
    } else if left[i] < right[j] {
      i += 1
    } else {
      j += 1
    }
  }
  result
}

///|
fn SupportIndex::candidates(self : SupportIndex, p : Pattern) -> Array[Int32] {
  let seen : Set[Int32] = Set([])
  let lists : Array[Array[Int32]] = []
  for event in p.itemsets {
    for item in event {
      if seen.contains(item) {
        continue
      }
      seen.add(item)
      match self.postings.get(item) {
        None => return []
        Some(ids) => lists.push(ids)
      }
    }
  }
  lists.sort_by(fn(a, b) { a.length().compare(b.length()) })
  let mut current = lists[0].copy()
  for i = 1; i < lists.length(); i = i + 1 {
    current = intersect_ids(current, lists[i])
    if current.is_empty() {
      break
    }
  }
  current
}

///|
/// Candidate intersection preserves sequence IDs; the exact matcher still
/// enforces event cooccurrence, order, and positional constraints.
pub fn SupportIndex::query_ids(
  self : SupportIndex,
  p : Pattern,
  constraints~ : Constraints = constraints(),
  max_steps~ : Int32 = 10000000,
) -> Array[Int32] raise MiningError {
  validate_pattern(p)
  validate_constraints(constraints)
  check_step_limit(max_steps)
  let budget = WorkBudget::{ steps: 0, limit: max_steps, }
  let result = []
  for sid in self.candidates(p) {
    if sequence_matches(self.snapshot.sequences[sid], p, constraints, budget) {
      result.push(sid)
    }
  }
  result
}

///|
pub fn SupportIndex::query_support(
  self : SupportIndex,
  p : Pattern,
  constraints~ : Constraints = constraints(),
  max_steps~ : Int32 = 10000000,
) -> Int32 raise MiningError {
  self.query_ids(p, constraints~, max_steps~).length()
}
