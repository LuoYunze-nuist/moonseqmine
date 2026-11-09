///|
/// Copy nested itemsets so callers can mutate results independently of inputs.
fn postprocess_copy_pattern(p : Pattern) -> Pattern {
  { itemsets: p.itemsets.map(fn(items) { items.copy() }), }
}

///|
/// Validate the entire supplied family and collapse identical support records.
/// Conflicting duplicates are invalid even when that pattern would be removed.
fn postprocess_family(
  patterns : Array[FrequentPattern],
) -> Array[FrequentPattern] raise MiningError {
  let unique : Array[FrequentPattern] = []
  for record in patterns {
    validate_pattern(record.pattern)
    if record.support < 1 {
      raise Invalid("pattern support must be positive")
    }
    let mut duplicate = false
    for previous in unique {
      if previous.pattern == record.pattern {
        if previous.support != record.support {
          raise Invalid("identical patterns have conflicting support")
        }
        duplicate = true
        break
      }
    }
    if !duplicate {
      unique.push({
        pattern: postprocess_copy_pattern(record.pattern),
        support: record.support,
      })
    }
  }
  unique.sort_by(fn(a, b) {
    pattern_key(a.pattern).compare(pattern_key(b.pattern))
  })
  unique
}

///|
fn postprocess_select(
  patterns : Array[FrequentPattern],
  same_support~ : Bool,
) -> Array[FrequentPattern] raise MiningError {
  let family = postprocess_family(patterns)
  let result : Array[FrequentPattern] = []
  for candidate in family {
    let mut removed = false
    for other in family {
      if item_count(candidate.pattern) < item_count(other.pattern) &&
        (!same_support || candidate.support == other.support) &&
        is_subpattern(candidate.pattern, other.pattern) {
        removed = true
        break
      }
    }
    if !removed {
      result.push(candidate)
    }
  }
  result
}

///|
/// Closed relative ONLY to the supplied, possibly bounded pattern family.
/// Remove a pattern if a strict superpattern in that family has equal support.
/// Identical records are deduplicated; results are sorted by pattern_key and
/// contain independent copies of every itemset. No database is consulted.
/// Supplied supports need not be antimonotone: max_gap constraints can break
/// that property for arbitrary subpatterns. This is not constrained closure.
pub fn closed_patterns(
  patterns : Array[FrequentPattern],
) -> Array[FrequentPattern] raise MiningError {
  postprocess_select(patterns, same_support=true)
}

///|
/// Maximal relative ONLY to the supplied, possibly bounded pattern family.
/// Remove a pattern if any strict superpattern occurs in that family.
/// Validation, deduplication, ordering and copy semantics match closed_patterns.
pub fn maximal_patterns(
  patterns : Array[FrequentPattern],
) -> Array[FrequentPattern] raise MiningError {
  postprocess_select(patterns, same_support=false)
}
