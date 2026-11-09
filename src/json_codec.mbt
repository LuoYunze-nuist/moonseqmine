///|
/// A cursor for the numeric array subset of JSON. Keeping the original digits
/// avoids rounding fractional or large JSON numbers through Double.
priv struct SequenceJsonReader {
  text : String
  mut offset : Int32
}

///|
fn SequenceJsonReader::error(
  self : SequenceJsonReader,
  message : String,
) -> MiningError {
  Parse("sequence JSON at UTF-16 offset \{self.offset}: \{message}")
}

///|
fn SequenceJsonReader::skip_space(self : SequenceJsonReader) -> Unit {
  while self.offset < self.text.length() {
    let code = self.text[self.offset].to_int()
    // JSON permits exactly these four whitespace characters.
    if code != 32 && code != 9 && code != 10 && code != 13 {
      break
    }
    self.offset += 1
  }
}

///|
fn SequenceJsonReader::take(self : SequenceJsonReader, code : Int32) -> Bool {
  self.skip_space()
  if self.offset < self.text.length() && self.text[self.offset].to_int() == code {
    self.offset += 1
    true
  } else {
    false
  }
}

///|
fn SequenceJsonReader::open_array(
  self : SequenceJsonReader,
) -> Unit raise MiningError {
  if !self.take(91) {
    raise self.error("expected '[' at this array level")
  }
}

///|
/// After an element, consume either the closing bracket or a comma. A comma
/// always requires another element; callers never accept a trailing comma.
fn SequenceJsonReader::more(
  self : SequenceJsonReader,
) -> Bool raise MiningError {
  if self.take(93) {
    false
  } else if self.take(44) {
    true
  } else {
    raise self.error("expected ',' or ']'")
  }
}

///|
fn SequenceJsonReader::item(
  self : SequenceJsonReader,
) -> Int32 raise MiningError {
  self.skip_space()
  let start = self.offset
  let mut value = 0
  while self.offset < self.text.length() {
    let digit = self.text[self.offset].to_int() - 48
    if digit < 0 || digit > 9 {
      break
    }
    if self.offset > start && self.text[start].to_int() == 48 {
      raise self.error("leading zeros are not valid JSON integers")
    }
    if value > 214748364 || (value == 214748364 && digit > 7) {
      raise self.error("item ID exceeds Int32 range")
    }
    value = value * 10 + digit
    self.offset += 1
  }
  if self.offset == start {
    raise self.error("expected a nonnegative decimal integer")
  }
  // Signs, decimal points and exponent markers are deliberately not consumed.
  // The surrounding array grammar then rejects them, rather than coercing.
  value
}

///|
fn SequenceJsonReader::itemset(
  self : SequenceJsonReader,
) -> Array[Int32] raise MiningError {
  self.open_array()
  if self.take(93) {
    raise self.error("empty itemsets are not allowed")
  }
  let items = []
  while true {
    items.push(self.item())
    if !self.more() {
      break
    }
  }
  items
}

///|
fn SequenceJsonReader::sequence(
  self : SequenceJsonReader,
) -> Array[Array[Int32]] raise MiningError {
  self.open_array()
  let events = []
  if self.take(93) {
    return events
  }
  while true {
    events.push(self.itemset())
    if !self.more() {
      break
    }
  }
  events
}

///|
fn SequenceJsonReader::finish(
  self : SequenceJsonReader,
) -> Unit raise MiningError {
  self.skip_space()
  if self.offset != self.text.length() {
    raise self.error("unexpected content after the root array")
  }
}

///|
/// Parse [[[item IDs], ...], ...]. Empty databases and empty sequences are
/// allowed, but itemsets must be nonempty. IDs use unsigned decimal integer
/// spelling in 0..2147483647: -0, +1, 1.0, 1e0 and leading zeros are rejected.
/// Parsing has fixed array depth and never recursively walks untrusted input.
pub fn parse_database_json(text : String) -> Database raise MiningError {
  let reader = SequenceJsonReader::{ text, offset: 0, }
  reader.open_array()
  let sequences = []
  if !reader.take(93) {
    while true {
      sequences.push(reader.sequence())
      if !reader.more() {
        break
      }
    }
  }
  reader.finish()
  database(sequences)
}

///|
/// Parse [[item IDs], ...] with the same integer rules as database JSON.
/// Patterns must contain at least one nonempty itemset.
pub fn parse_pattern_json(text : String) -> Pattern raise MiningError {
  let reader = SequenceJsonReader::{ text, offset: 0, }
  let events = reader.sequence()
  reader.finish()
  pattern(events)
}

///|
fn write_sequence_json(
  out : StringBuilder,
  sequence : Array[Array[Int32]],
) -> Unit {
  out.write_char('[')
  for event_index, event in sequence {
    if event_index != 0 {
      out.write_char(',')
    }
    out.write_char('[')
    for item_index, item in event {
      if item_index != 0 {
        out.write_char(',')
      }
      out.write_string(item.to_string())
    }
    out.write_char(']')
  }
  out.write_char(']')
}

///|
/// Emit compact canonical arrays after checking the public model's invariants.
pub fn format_database_json(db : Database) -> String raise MiningError {
  validate_database(db)
  let out = StringBuilder()
  out.write_char('[')
  for index, sequence in db.sequences {
    if index != 0 {
      out.write_char(',')
    }
    write_sequence_json(out, sequence)
  }
  out.write_char(']')
  out.to_string()
}

///|
pub fn format_pattern_json(p : Pattern) -> String raise MiningError {
  validate_pattern(p)
  let out = StringBuilder()
  write_sequence_json(out, p.itemsets)
  out.to_string()
}
