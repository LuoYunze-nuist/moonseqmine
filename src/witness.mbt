///|
fn collect_witnesses(
  seq : Array[Array[Int32]],
  p : Pattern,
  sid : Int32,
  c : Constraints,
  positions : Array[Int32],
  out : Array[Witness],
  max_witnesses : Int32,
  budget : WorkBudget,
) -> Unit raise MiningError {
  let depth = positions.length()
  if depth == p.itemsets.length() {
    if out.length() >= max_witnesses {
      raise Resource("witness limit exceeded")
    }
    out.push({ sequence_id: sid, positions: positions.copy(), })
    return
  }
  let last = if positions.is_empty() { -1 } else { positions[depth - 1] }
  let first = if positions.is_empty() { -1 } else { positions[0] }
  for pos = last + 1; pos < seq.length(); pos = pos + 1 {
    budget.tick()
    if !position_allowed(first, last, pos, c) {
      break
    }
    if contains_itemset(seq[pos], p.itemsets[depth]) {
      positions.push(pos)
      collect_witnesses(seq, p, sid, c, positions, out, max_witnesses, budget)
      let _ = positions.pop()
    }
  }
}

///|
/// Enumerate complete evidence or raise; never silently return truncated evidence.
/// Patterns are limited to 64 itemsets to bound recursive stack depth.
pub fn witnesses(
  db : Database,
  p : Pattern,
  constraints~ : Constraints = constraints(),
  max_witnesses~ : Int32 = 10000,
  max_steps~ : Int32 = 10000000,
) -> Array[Witness] raise MiningError {
  validate_database(db)
  validate_pattern(p)
  validate_constraints(constraints)
  check_step_limit(max_steps)
  if p.itemsets.length() > 64 {
    raise Invalid("witness pattern exceeds 64 itemsets")
  }
  if max_witnesses < 1 {
    raise Invalid("max_witnesses must be positive")
  }
  let out = []
  let budget = WorkBudget::{ steps: 0, limit: max_steps, }
  for sid = 0; sid < db.sequences.length(); sid = sid + 1 {
    collect_witnesses(
      db.sequences[sid],
      p,
      sid,
      constraints,
      [],
      out,
      max_witnesses,
      budget,
    )
  }
  out
}

///|
/// Validate externally stored evidence, including its gap/span contract.
pub fn verify_witness(
  db : Database,
  p : Pattern,
  witness : Witness,
  constraints~ : Constraints = constraints(),
) -> Bool raise MiningError {
  validate_database(db)
  validate_pattern(p)
  validate_constraints(constraints)
  if witness.sequence_id < 0 || witness.sequence_id >= db.sequences.length() {
    return false
  }
  if witness.positions.length() != p.itemsets.length() {
    return false
  }
  let seq = db.sequences[witness.sequence_id]
  let mut last = -1
  let mut first = -1
  for i = 0; i < witness.positions.length(); i = i + 1 {
    let pos = witness.positions[i]
    if pos <= last || pos >= seq.length() {
      return false
    }
    if !position_allowed(first, last, pos, constraints) {
      return false
    }
    if !contains_itemset(seq[pos], p.itemsets[i]) {
      return false
    }
    if first < 0 {
      first = pos
    }
    last = pos
  }
  true
}
