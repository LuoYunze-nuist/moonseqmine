///|
/// A sequence pattern. Events are strictly increasing, nonempty itemsets.
#derive(Eq, Debug)
pub(all) struct Pattern {
  itemsets : Array[Array[Int32]]
}

///|
/// A database counts each sequence once, including empty sequences in its size.
#derive(Eq, Debug)
pub(all) struct Database {
  sequences : Array[Array[Array[Int32]]]
}

///|
/// Inclusive positional limits: gap is skipped itemsets; span is last-first.
#derive(Eq, Debug)
pub(all) struct Constraints {
  max_gap : Int32?
  max_span : Int32?
}

///|
/// Mining limits. Exceeding a budget raises an error without partial output.
#derive(Eq, Debug)
pub(all) struct Options {
  min_support : Int32
  max_items : Int32
  max_patterns : Int32
  max_states : Int32
  max_steps : Int32
}

///|
/// Support is the number of distinct database sequence IDs.
#derive(Eq, Debug)
pub(all) struct FrequentPattern {
  pattern : Pattern
  support : Int32
}

///|
/// One embedding, as zero-based itemset positions in a single sequence.
#derive(Eq, Debug)
pub(all) struct Witness {
  sequence_id : Int32
  positions : Array[Int32]
}

///|
#derive(Eq, Debug)
pub(all) suberror MiningError {
  Invalid(String)
  Resource(String)
  Parse(String)
}

///|
pub fn constraints(max_gap? : Int32, max_span? : Int32) -> Constraints {
  { max_gap, max_span, }
}

///|
pub fn options(
  min_support : Int32,
  max_items~ : Int32 = 8,
  max_patterns~ : Int32 = 10000,
  max_states~ : Int32 = 1000000,
  max_steps~ : Int32 = 10000000,
) -> Options {
  { min_support, max_items, max_patterns, max_states, max_steps, }
}

///|
pub fn validate_constraints(c : Constraints) -> Unit raise MiningError {
  if c.max_gap is Some(n) && n < 0 {
    raise Invalid("max_gap must be nonnegative")
  }
  if c.max_span is Some(n) && n < 0 {
    raise Invalid("max_span must be nonnegative")
  }
}

///|
pub fn validate_options(o : Options) -> Unit raise MiningError {
  if o.min_support < 1 {
    raise Invalid("min_support must be positive")
  }
  if o.max_items < 1 || o.max_items > 64 {
    raise Invalid("max_items must be in 1..64")
  }
  if o.max_patterns < 1 || o.max_states < 1 || o.max_steps < 1 {
    raise Invalid("resource limits must be positive")
  }
}

///|
pub extend Pattern with Eq::{equal, not_equal}

///|
pub extend Pattern with @debug.Debug::{to_repr}

///|
pub extend Database with Eq::{equal, not_equal}

///|
pub extend Database with @debug.Debug::{to_repr}

///|
pub extend Constraints with Eq::{equal, not_equal}

///|
pub extend Constraints with @debug.Debug::{to_repr}

///|
pub extend Options with Eq::{equal, not_equal}

///|
pub extend Options with @debug.Debug::{to_repr}

///|
pub extend FrequentPattern with Eq::{equal, not_equal}

///|
pub extend FrequentPattern with @debug.Debug::{to_repr}

///|
pub extend Witness with Eq::{equal, not_equal}

///|
pub extend Witness with @debug.Debug::{to_repr}

///|
pub extend MiningError with Eq::{equal, not_equal}

///|
pub extend MiningError with @debug.Debug::{to_repr}
