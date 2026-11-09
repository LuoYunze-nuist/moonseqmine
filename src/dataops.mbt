///|
/// A copied subset and a stable map from its local IDs to original IDs.
pub(all) struct DatabaseSelection {
  database : Database
  source_ids : Array[Int32]
} derive(Eq, Debug)

///|
pub extend DatabaseSelection with Eq::{equal, not_equal}

///|
pub extend DatabaseSelection with @debug.Debug::{to_repr}

///|
/// Reject duplicate IDs rather than accidentally double-weighting support.
pub fn select_sequences(
  db : Database,
  ids : Array[Int32],
) -> DatabaseSelection raise MiningError {
  validate_database(db)
  let seen : Set[Int32] = Set([])
  let sequences = []
  for id in ids {
    if id < 0 || id >= db.sequences.length() {
      raise Invalid("selected sequence ID out of range")
    }
    if seen.contains(id) {
      raise Invalid("duplicate selected sequence ID")
    }
    seen.add(id)
    sequences.push(db.sequences[id].map(fn(event) { event.copy() }))
  }
  { database: { sequences, }, source_ids: ids.copy(), }
}

///|
/// Complementary cohorts preserve each original record exactly once.
pub fn partition_database(
  db : Database,
  selected_ids : Array[Int32],
) -> (DatabaseSelection, DatabaseSelection) raise MiningError {
  let selected = select_sequences(db, selected_ids)
  let used = Set::from_array(selected_ids)
  let complement = []
  for id = 0; id < db.sequences.length(); id = id + 1 {
    if !used.contains(id) {
      complement.push(id)
    }
  }
  (selected, select_sequences(db, complement))
}

///|
/// Convert a positive rational support fraction to a count using exact Int64
/// arithmetic. Empty databases yield zero; mine itself requires a positive count.
pub fn relative_min_support(
  database_size : Int32,
  numerator : Int32,
  denominator : Int32,
) -> Int32 raise MiningError {
  if database_size < 0 {
    raise Invalid("database_size must be nonnegative")
  }
  if numerator < 1 || denominator < 1 || numerator > denominator {
    raise Invalid("support fraction must be in (0,1]")
  }
  let product = database_size.to_int64() * numerator.to_int64()
  let divisor = denominator.to_int64()
  ((product + divisor - 1L) / divisor).to_int()
}

///|
pub(all) struct ItemFrequency {
  item : Int32
  sequence_support : Int32
  event_occurrences : Int32
} derive(Eq, Debug)

///|
pub extend ItemFrequency with Eq::{equal, not_equal}

///|
pub extend ItemFrequency with @debug.Debug::{to_repr}

///|
/// Totals use Int64 because callers may concatenate many large records.
pub(all) struct DatabaseSummary {
  sequences : Int32
  empty_sequences : Int32
  events : Int64
  items : Int64
  max_sequence_length : Int32
  alphabet : Array[ItemFrequency]
} derive(Eq, Debug)

///|
pub extend DatabaseSummary with Eq::{equal, not_equal}

///|
pub extend DatabaseSummary with @debug.Debug::{to_repr}

///|
pub fn summarize_database(db : Database) -> DatabaseSummary raise MiningError {
  validate_database(db)
  let counts : Map[Int32, Int32] = Map([])
  let supports : Map[Int32, Int32] = Map([])
  let mut empty = 0
  let mut events = 0L
  let mut items = 0L
  let mut longest = 0
  for seq in db.sequences {
    if seq.is_empty() {
      empty += 1
    }
    events += seq.length().to_int64()
    if seq.length() > longest {
      longest = seq.length()
    }
    let seen : Set[Int32] = Set([])
    for event in seq {
      items += event.length().to_int64()
      for item in event {
        let count = counts.get(item).unwrap_or(0)
        if count == 2147483647 {
          raise Resource("item occurrence count exceeds Int32")
        }
        counts[item] = count + 1
        if !seen.contains(item) {
          seen.add(item)
          supports[item] = supports.get(item).unwrap_or(0) + 1
        }
      }
    }
  }
  let keys : Array[Int32] = []
  for key, _ in counts {
    keys.push(key)
  }
  keys.sort()
  let alphabet = keys.map(fn(item) {
    { item, sequence_support: supports[item], event_occurrences: counts[item], }
  })
  {
    sequences: db.sequences.length(),
    empty_sequences: empty,
    events,
    items,
    max_sequence_length: longest,
    alphabet,
  }
}
