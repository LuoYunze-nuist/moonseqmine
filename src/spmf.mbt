///|
fn spmf_space(code : Int32) -> Bool {
  code == 32 || (code >= 9 && code <= 13)
}

///|
fn spmf_error(offset : Int32, message : String) -> MiningError {
  Parse("SPMF at UTF-16 offset \{offset}: \{message}")
}

///|
/// Parse a whitespace-delimited SPMF stream. Records may span lines and multiple
/// records may share a line. #, %, and @ introduce whole-line comments only,
/// with optional leading whitespace. Empty sequences are written as -2.
/// Item IDs must be positive Int32 values; -1 closes a nonempty itemset.
/// Constructors normalize item order and remove duplicate IDs within itemsets.
pub fn parse_spmf(text : String) -> Database raise MiningError {
  let sequences : Array[Array[Array[Int32]]] = []
  let mut sequence : Array[Array[Int32]] = []
  let mut itemset : Array[Int32] = []
  let mut offset = 0
  let mut line_start = true
  while offset < text.length() {
    let code = text[offset].to_int()
    if spmf_space(code) {
      if code == 10 || code == 13 {
        line_start = true
      }
      offset += 1
      continue
    }
    if line_start && (code == 35 || code == 37 || code == 64) {
      while offset < text.length() &&
            text[offset].to_int() != 10 &&
            text[offset].to_int() != 13 {
        offset += 1
      }
      continue
    }
    line_start = false
    let start = offset
    let negative = code == 45
    if negative {
      offset += 1
    }
    let digit_start = offset
    let mut value = 0
    while offset < text.length() {
      let digit = text[offset].to_int() - 48
      if digit < 0 || digit > 9 {
        break
      }
      // Check before multiplication: wrapping must never admit an invalid ID.
      if value > 214748364 || (value == 214748364 && digit > 7) {
        raise spmf_error(start, "integer overflow")
      }
      value = value * 10 + digit
      offset += 1
    }
    if offset == digit_start {
      raise spmf_error(start, "expected decimal integer")
    }
    if offset < text.length() && !spmf_space(text[offset].to_int()) {
      raise spmf_error(offset, "integer must end at whitespace or EOF")
    }
    if negative {
      if offset - start != 2 || (value != 1 && value != 2) {
        raise spmf_error(start, "only -1 and -2 are valid negative tokens")
      }
      if value == 1 {
        if itemset.is_empty() {
          raise spmf_error(start, "empty itemset")
        }
        sequence.push(itemset)
        itemset = []
      } else {
        if !itemset.is_empty() {
          raise spmf_error(start, "missing -1 before -2")
        }
        sequences.push(sequence)
        sequence = []
      }
    } else {
      if value == 0 {
        raise spmf_error(start, "item IDs must be positive")
      }
      itemset.push(value)
    }
  }
  if !itemset.is_empty() {
    raise spmf_error(offset, "truncated itemset: missing -1 and -2")
  }
  if !sequence.is_empty() {
    raise spmf_error(offset, "truncated sequence: missing -2")
  }
  database(sequences)
}

///|
/// Emit one sequence per line, with a trailing newline for each sequence.
/// An empty database formats as an empty string. Zero-based model IDs cannot
/// be represented in SPMF and are rejected, never implicitly renumbered.
pub fn format_spmf(db : Database) -> String raise MiningError {
  validate_database(db)
  let out = StringBuilder()
  for sequence in db.sequences {
    for itemset in sequence {
      for item in itemset {
        if item == 0 {
          raise Invalid("SPMF cannot represent item ID zero")
        }
        out.write_string(item.to_string())
        out.write_char(' ')
      }
      out.write_string("-1 ")
    }
    out.write_string("-2\n")
  }
  out.to_string()
}
