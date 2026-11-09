///|
test "json database exact integers normalization and round trip" {
  let db = parse_database_json(" \r\n[[], [[2,0,2],[2147483647]]]\t")
  assert_eq(db.sequences, [[], [[0, 2], [2147483647]]])
  let text = format_database_json(db)
  assert_eq(text, "[[],[[0,2],[2147483647]]]")
  assert_eq(parse_database_json(text), db)
  assert_eq(format_database_json(parse_database_json("[]")), "[]")
}

///|
test "json pattern canonical round trip" {
  let p = parse_pattern_json("[[3, 1, 3], [0]]")
  assert_eq(p.itemsets, [[1, 3], [0]])
  assert_eq(format_pattern_json(p), "[[1,3],[0]]")
  assert_eq(parse_pattern_json(format_pattern_json(p)), p)
}

///|
test "json rejects numbers without integer spelling or within overflow" {
  for
    token in [
      "-1", "-0", "+1", "01", "00", "1.0", "0.0", "1e0", "1E+0", "1e-1", "2147483648",
      "9007199254740993", "99999999999999999999999999", "1.00000000000000000000000001",
      "2147483647.00000000001", "null", "true", "false", "NaN", "Infinity", "\"1\"",
      "１", "[]", "{}",
    ] {
    let pattern_rejected = try {
      let _ = parse_pattern_json("[[" + token + "]]")
      false
    } catch {
      Parse(_) => true
      _ => false
    }
    let database_rejected = try {
      let _ = parse_database_json("[[[" + token + "]]]")
      false
    } catch {
      Parse(_) => true
      _ => false
    }
    assert_true(pattern_rejected, msg=token)
    assert_true(database_rejected, msg=token)
  }
}

///|
test "json rejects wrong array levels trailing data and malformed punctuation" {
  for
    text in [
      "", "null", "{}", "0", "[0]", "[[0]]", "[[[[0]]]]", "[[[]]]", "[", "[[", "[[[",
      "[[[1", "[[[1]", "[[[1]]", "[[[1,]]]", "[[[1],]]", "[[[1]],]", "[, ]", "[[[1 2]]]",
      "[[[1,,2]]]", "[] []", "[]x", "/* comment */[]", "[// comment\n]", "\u{feff}[]",
      "\u{00a0}[]", "\u{000b}[]", "\u{000c}[]", "[[[1\u{0000}]]]",
    ] {
    let rejected = try {
      let _ = parse_database_json(text)
      false
    } catch {
      Parse(_) => true
      _ => false
    }
    assert_true(rejected, msg=text)
  }
  for text in ["[]", "[[]]", "[1]", "[[[1]]]", "[[1],]", "[[1]]x"] {
    let rejected = try {
      let _ = parse_pattern_json(text)
      false
    } catch {
      _ => true
    }
    assert_true(rejected, msg=text)
  }
}

///|
test "json formatters reject malformed public values" {
  for events in [[[-1]], [[2, 1]], [[1, 1]], [[]]] {
    let bad_pattern = try {
      let _ = format_pattern_json({ itemsets: events, })
      false
    } catch {
      Invalid(_) => true
      _ => false
    }
    let bad_database = try {
      let _ = format_database_json({ sequences: [events], })
      false
    } catch {
      Invalid(_) => true
      _ => false
    }
    assert_true(bad_pattern)
    assert_true(bad_database)
  }
  let empty = try {
    let _ = format_pattern_json({ itemsets: [], })
    false
  } catch {
    Invalid(_) => true
    _ => false
  }
  assert_true(empty)
}
