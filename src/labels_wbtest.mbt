///|
test "labels dictionary retains first insertion order and exact spellings" {
  let dictionary = label_dictionary()
  for index, label in ["z", "a", "", "中文", "😀", "A", "é", "e\u{0301}"] {
    assert_eq(intern_label(dictionary, label), index)
    assert_eq(label_of(dictionary, index), Some(label))
  }
  assert_eq(intern_label(dictionary, "z"), 0)
  assert_eq(intern_label(dictionary, "中文"), 3)
  assert_eq(intern_label(dictionary, "next"), 8)
  assert_eq(label_of(dictionary, -1), None)
  assert_eq(label_of(dictionary, 9), None)
  assert_eq(label_of(dictionary, 2147483647), None)
  let independent = label_dictionary()
  assert_eq(intern_label(independent, "a"), 0)
  assert_eq(label_of(dictionary, 0), Some("z"))
}

///|
test "labels encode normalizes itemsets and decodes in stable ID order" {
  let input = [[["z", "a", "z"], ["a", "z", "中文"]], [], [["中文", ""]]]
  let (db, dictionary) = encode_labeled_sequences(input)
  assert_eq(db.sequences, [[[0, 1], [0, 1, 2]], [], [[2, 3]]])
  assert_eq(label_of(dictionary, 0), Some("z"))
  assert_eq(label_of(dictionary, 1), Some("a"))
  let decoded = decode_labeled_sequences(db, dictionary)
  assert_eq(decoded, [[["z", "a"], ["z", "a", "中文"]], [], [["中文", ""]]])
  let (again, again_dictionary) = encode_labeled_sequences(decoded)
  assert_eq(again, db)
  assert_eq(decode_labeled_sequences(again, again_dictionary), decoded)
  assert_eq(parse_database_json(format_database_json(db)), db)
}

///|
test "labels encoding and decoding do not alias caller arrays" {
  let input = [[["first", "second"]]]
  let (db, dictionary) = encode_labeled_sequences(input)
  input[0][0][0] = "changed"
  input[0].push(["new"])
  assert_eq(db.sequences, [[[0, 1]]])
  assert_eq(label_of(dictionary, 0), Some("first"))
  let decoded = decode_labeled_sequences(db, dictionary)
  decoded[0][0][0] = "replaced"
  decoded[0].push(["extra"])
  assert_eq(decode_labeled_sequences(db, dictionary), [[["first", "second"]]])
  assert_eq(intern_label(dictionary, "third"), 2)
  assert_eq(decode_labeled_sequences(db, dictionary), [[["first", "second"]]])
}

///|
test "labels empty inputs and malformed itemsets" {
  let (empty_db, empty_dictionary) = encode_labeled_sequences([])
  assert_eq(empty_db.sequences, [])
  assert_eq(label_of(empty_dictionary, 0), None)
  assert_eq(decode_labeled_sequences(empty_db, empty_dictionary), [])
  let (db, dictionary) = encode_labeled_sequences([[], []])
  assert_eq(db.sequences, [[], []])
  assert_eq(decode_labeled_sequences(db, dictionary), [[], []])
  let bad = try {
    let _ = encode_labeled_sequences([[["valid"]], [[]]])
    false
  } catch {
    Invalid(_) => true
    _ => false
  }
  assert_true(bad)
}

///|
test "labels decode rejects unknown IDs and invalid public database values" {
  let dictionary = label_dictionary()
  let _ = intern_label(dictionary, "known")
  for
    sequences in [
      [[[1]]],
      [[[2147483647]]],
      [[[-1]]],
      [[[0, 0]]],
      [[[1, 0]]],
      [[[]]],
    ] {
    let rejected = try {
      let _ = decode_labeled_sequences({ sequences, }, dictionary)
      false
    } catch {
      Invalid(_) => true
      _ => false
    }
    assert_true(rejected)
  }
  let rejected = try {
    let _ = decode_labeled_sequences(database([[[0]]]), label_dictionary())
    false
  } catch {
    Invalid(_) => true
    _ => false
  }
  assert_true(rejected)
}
