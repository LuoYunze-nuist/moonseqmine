///|
/// Work counters describe projection operations, not validation or wall time.
#derive(Eq, Debug)
pub(all) struct MiningStats {
  steps : Int32
  generated_states : Int32
  emitted_patterns : Int32
}

///|
pub extend MiningStats with Eq::{equal, not_equal}

///|
pub extend MiningStats with @debug.Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct MiningResult {
  patterns : Array[FrequentPattern]
  stats : MiningStats
}

///|
pub extend MiningResult with Eq::{equal, not_equal}

///|
pub extend MiningResult with @debug.Debug::{to_repr}

///|
priv struct ProjectionBudget {
  work : WorkBudget
  mut states : Int32
  options : Options
}

///|
fn ProjectionBudget::state(self : ProjectionBudget) -> Unit raise MiningError {
  if self.states >= self.options.max_states {
    raise Resource("projection state budget exceeded")
  }
  self.states += 1
}

// Each state is (sequence ID, first itemset position, last itemset position).
// Distinct starts must survive max_span and max_gap constraints.

///|
fn extend_projection(
  db : Database,
  prefix : Pattern,
  states : Array[(Int32, Int32, Int32)],
  same_event : Bool,
  c : Constraints,
  budget : ProjectionBudget,
) -> Map[Int32, Array[(Int32, Int32, Int32)]] raise MiningError {
  let out : Map[Int32, Array[(Int32, Int32, Int32)]] = Map([])
  let seen : Set[(Int32, Int32, Int32, Int32)] = Set([])
  let last_item = if prefix.itemsets.is_empty() {
    -1
  } else {
    let last = prefix.itemsets[prefix.itemsets.length() - 1]
    last[last.length() - 1]
  }
  for state in states {
    let (sid, first, last) = state
    let seq = db.sequences[sid]
    if same_event {
      if last < 0 {
        continue
      }
      for item in seq[last] {
        budget.work.tick()
        if item <= last_item {
          continue
        }
        let key = (item, sid, first, last)
        if seen.contains(key) {
          continue
        }
        seen.add(key)
        budget.state()
        let entries = out.get_or_init(item, fn() { [] })
        entries.push(state)
      }
    } else {
      for pos = last + 1; pos < seq.length(); pos = pos + 1 {
        budget.work.tick()
        if !position_allowed(first, last, pos, c) {
          break
        }
        let start = if first < 0 { pos } else { first }
        for item in seq[pos] {
          budget.work.tick()
          let key = (item, sid, start, pos)
          if seen.contains(key) {
            continue
          }
          seen.add(key)
          budget.state()
          let entries = out.get_or_init(item, fn() { [] })
          entries.push((sid, start, pos))
        }
      }
    }
  }
  out
}

///|
fn projection_support(states : Array[(Int32, Int32, Int32)]) -> Int32 {
  let ids : Set[Int32] = Set([])
  for state in states {
    ids.add(state.0)
  }
  ids.length()
}

///|
fn grow_prefix(
  db : Database,
  prefix : Pattern,
  states : Array[(Int32, Int32, Int32)],
  depth : Int32,
  c : Constraints,
  budget : ProjectionBudget,
  out : Array[FrequentPattern],
) -> Unit raise MiningError {
  if depth >= budget.options.max_items {
    return
  }
  // I then S, sorted IDs, yields a deterministic traversal independent of maps.
  for same_event in [true, false] {
    if same_event && prefix.itemsets.is_empty() {
      continue
    }
    let projections = extend_projection(
      db, prefix, states, same_event, c, budget,
    )
    let keys : Array[Int32] = []
    for key, _ in projections {
      keys.push(key)
    }
    keys.sort()
    for item in keys {
      let next_states = projections[item]
      let count = projection_support(next_states)
      if count < budget.options.min_support {
        continue
      }
      if out.length() >= budget.options.max_patterns {
        raise Resource("pattern result budget exceeded")
      }
      let itemsets = prefix.itemsets.map(fn(event) { event.copy() })
      if same_event {
        itemsets[itemsets.length() - 1].push(item)
      } else {
        itemsets.push([item])
      }
      let next = Pattern::{ itemsets, }
      // Output arrays do not alias the prefix used to grow descendants.
      out.push({
        pattern: { itemsets: itemsets.map(fn(event) { event.copy() }), },
        support: count,
      })
      grow_prefix(db, next, next_states, depth + 1, c, budget, out)
    }
  }
}

///|
/// Prefix-projected frequent discovery, including both itemset and sequence growth.
/// max_items bounds the declared pattern family. All budgets are hard failures.
pub fn mine_with_stats(
  db : Database,
  options : Options,
  constraints~ : Constraints = constraints(),
) -> MiningResult raise MiningError {
  validate_database(db)
  validate_options(options)
  validate_constraints(constraints)
  let out : Array[FrequentPattern] = []
  let budget = ProjectionBudget::{
    work: { steps: 0, limit: options.max_steps, },
    states: 0,
    options,
  }
  if options.min_support > db.sequences.length() {
    return {
      patterns: out,
      stats: { steps: 0, generated_states: 0, emitted_patterns: 0, },
    }
  }
  let initial = []
  for sid = 0; sid < db.sequences.length(); sid = sid + 1 {
    budget.state()
    initial.push((sid, -1, -1))
  }
  grow_prefix(db, { itemsets: [], }, initial, 0, constraints, budget, out)
  {
    patterns: out,
    stats: {
      steps: budget.work.steps,
      generated_states: budget.states,
      emitted_patterns: out.length(),
    },
  }
}

///|
pub fn mine(
  db : Database,
  options : Options,
  constraints~ : Constraints = constraints(),
) -> Array[FrequentPattern] raise MiningError {
  mine_with_stats(db, options, constraints~).patterns
}
