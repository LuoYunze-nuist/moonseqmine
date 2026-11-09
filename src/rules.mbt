///|
/// A descriptive, unconstrained sequential association at an itemset boundary.
/// Prefix and suffix occurrences may have additional embeddings in a sequence;
/// these statistics describe co-occurrence/order, never a causal implication.
pub(all) struct SequentialRule {
  prefix : Pattern
  suffix : Pattern
  support : Int32
  prefix_support : Int32
  suffix_support : Int32
  database_size : Int32
  confidence : Double
  lift : Double
} derive(Eq, Debug)

///|
pub extend SequentialRule with Eq::{equal, not_equal}

///|
pub extend SequentialRule with @debug.Debug::{to_repr}

///|
fn rule_slice(p : Pattern, start : Int32, end : Int32) -> Pattern {
  let itemsets = []
  for i = start; i < end; i = i + 1 {
    itemsets.push(p.itemsets[i].copy())
  }
  { itemsets, }
}

///|
/// Split each supplied pattern only between complete itemsets. Recompute all
/// support without positional constraints and reject stale supplied counts,
/// including counts of patterns with no possible split. This API must not be
/// interpreted as rules under max_gap/max_span constraints.
///
/// confidence = support(full)/support(prefix).
/// lift = confidence/(support(suffix)/database_size).
/// Positive verified full support guarantees nonzero denominators. Empty
/// databases return no rules after structural/input validation. Identical input
/// records are deduplicated; ordering is by full pattern_key then split index.
/// Every returned prefix and suffix owns independent nested itemset arrays.
pub fn sequential_rules(
  db : Database,
  patterns : Array[FrequentPattern],
  min_confidence~ : Double = 0.0,
) -> Array[SequentialRule] raise MiningError {
  if min_confidence != min_confidence ||
    min_confidence < 0.0 ||
    min_confidence > 1.0 {
    raise Invalid("min_confidence must be finite and in 0..1")
  }
  validate_database(db)
  let family = postprocess_family(patterns)
  let database_size = db.sequences.length()
  if database_size == 0 {
    return []
  }
  let index = support_index(db)
  let result : Array[SequentialRule] = []
  for record in family {
    let full_support = index.query_support(record.pattern)
    if full_support != record.support {
      raise Invalid(
        "supplied support differs from unconstrained database support",
      )
    }
    for split = 1; split < record.pattern.itemsets.length(); split = split + 1 {
      let prefix = rule_slice(record.pattern, 0, split)
      let suffix = rule_slice(
        record.pattern,
        split,
        record.pattern.itemsets.length(),
      )
      let prefix_support = index.query_support(prefix)
      let suffix_support = index.query_support(suffix)
      let confidence = full_support.to_double() / prefix_support.to_double()
      if confidence >= min_confidence {
        result.push({
          prefix,
          suffix,
          support: full_support,
          prefix_support,
          suffix_support,
          database_size,
          confidence,
          lift: confidence /
          (suffix_support.to_double() / database_size.to_double()),
        })
      }
    }
  }
  result
}
