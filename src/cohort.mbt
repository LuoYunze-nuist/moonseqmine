///|
/// Descriptive support comparison of two cohorts; difference is foreground
/// rate minus background rate. A zero background rate has no finite ratio.
pub(all) struct CohortComparison {
  pattern : Pattern
  foreground_support : Int32
  background_support : Int32
  foreground_size : Int32
  background_size : Int32
  foreground_rate : Double
  background_rate : Double
  difference : Double
  ratio : Double?
} derive(Eq, Debug)

///|
pub extend CohortComparison with Eq::{equal, not_equal}

///|
pub extend CohortComparison with @debug.Debug::{to_repr}

///|
fn cohort_rate(count : Int32, size : Int32) -> Double {
  if size == 0 {
    0.0
  } else {
    count.to_double() / size.to_double()
  }
}

///|
/// Compare sequence-level support under identical positional constraints.
/// Empty cohorts have rate 0.0; empty sequences still count toward cohort size.
/// Preserve the supplied pattern order, including duplicate queries, and copy
/// nested itemsets into each result. max_steps is a budget per support query.
/// This comparison describes the supplied data and makes no causal claim.
pub fn compare_cohorts(
  foreground : Database,
  background : Database,
  patterns : Array[Pattern],
  constraints~ : Constraints = constraints(),
  max_steps~ : Int32 = 10000000,
) -> Array[CohortComparison] raise MiningError {
  validate_database(foreground)
  validate_database(background)
  validate_constraints(constraints)
  if max_steps < 1 {
    raise Invalid("max_steps must be positive")
  }
  for p in patterns {
    validate_pattern(p)
  }
  let result : Array[CohortComparison] = []
  for p in patterns {
    let foreground_support = support(foreground, p, constraints~, max_steps~)
    let background_support = support(background, p, constraints~, max_steps~)
    let foreground_size = foreground.sequences.length()
    let background_size = background.sequences.length()
    let foreground_rate = cohort_rate(foreground_support, foreground_size)
    let background_rate = cohort_rate(background_support, background_size)
    let ratio = if background_rate == 0.0 {
      None
    } else {
      Some(foreground_rate / background_rate)
    }
    result.push({
      pattern: postprocess_copy_pattern(p),
      foreground_support,
      background_support,
      foreground_size,
      background_size,
      foreground_rate,
      background_rate,
      difference: foreground_rate - background_rate,
      ratio,
    })
  }
  result
}
