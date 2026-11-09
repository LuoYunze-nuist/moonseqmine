///|
test "spmf round trip normalizes itemsets and preserves empty records" {
  let parsed = parse_spmf("3 1 3 -1 2 -1 -2\n-2\n2147483647 -1 -2")
  assert_eq(parsed.sequences, [[[1, 3], [2]], [], [[2147483647]]])
  let text = format_spmf(parsed)
  assert_eq(text, "1 3 -1 2 -1 -2\n-2\n2147483647 -1 -2\n")
  assert_eq(parse_spmf(text), parsed)
}

///|
test "spmf comments whitespace and stream boundaries" {
  assert_eq(parse_spmf("").sequences, [])
  assert_eq(format_spmf(database([])), "")
  let text = "  # header\r\n\t% comment\r@ metadata\n1\t2\n-1\n # between tokens\n-2 -2\n"
  assert_eq(parse_spmf(text).sequences, [[[1, 2]], []])
  assert_eq(parse_spmf("-2\r-2").sequences, [[], []])
  assert_eq(parse_spmf("0001 -1 -2").sequences, [[[1]]])
  assert_eq(parse_spmf("# end of file").sequences, [])
}

///|
test "spmf rejects malformed integers sentinels and truncated records" {
  for
    text in [
      "0 -1 -2", "-0 -1 -2", "-3", "-01", "-02", "-", "+1 -1 -2", "2147483648 -1 -2",
      "999999999999999999999999 -1 -2", "-2147483648", "1.0 -1 -2", "1e0 -1 -2",
      "1x -1 -2", "1-1 -2", "١ -1 -2", "1 -1 -2 # inline", "1 -1 -2\u{00a0}", "-1 -2",
      "1 -2", "1", "1 -1", "1 -1 -1 -2", "-2 1", "-2 -1", "1 -1\n# truncated",
    ] {
    let rejected = try {
      let _ = parse_spmf(text)
      false
    } catch {
      Parse(_) => true
      _ => false
    }
    assert_true(rejected, msg=text)
  }
}

///|
test "spmf formatter validates public database values and rejects zero" {
  for raw in [[[[0]]], [[[-1]]], [[[2, 1]]], [[[1, 1]]], [[[]]]] {
    let rejected = try {
      let _ = format_spmf({ sequences: raw, })
      false
    } catch {
      Invalid(_) => true
      _ => false
    }
    assert_true(rejected)
  }
}
