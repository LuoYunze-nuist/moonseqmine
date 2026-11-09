///|
/// A mutable, insertion-ordered dictionary. IDs start at zero and never move.
/// Label spellings are exact: empty strings and Unicode are accepted without
/// trimming, case folding, or Unicode normalization. Storage stays private so
/// callers cannot invalidate IDs already stored in a database.
pub struct LabelDictionary {
  priv labels : Array[String]
  priv ids : Map[String, Int32]
}

///|
pub fn label_dictionary() -> LabelDictionary {
  { labels: [], ids: Map([]), }
}

///|
/// Return an existing ID or append a label. Copies of a dictionary value share
/// its mutable storage; construct another dictionary for an independent mapping.
pub fn intern_label(
  dictionary : LabelDictionary,
  label : String,
) -> Int32 raise MiningError {
  match dictionary.ids.get(label) {
    Some(id) => id
    None => {
      let id = dictionary.labels.length()
      if id == 2147483647 {
        raise Resource("label dictionary exceeds Int32 capacity")
      }
      dictionary.labels.push(label)
      dictionary.ids.set(label, id)
      id
    }
  }
}

///|
/// Invalid IDs, including negative IDs, return None without indexing storage.
pub fn label_of(dictionary : LabelDictionary, id : Int32) -> String? {
  if id < 0 || id >= dictionary.labels.length() {
    None
  } else {
    Some(dictionary.labels[id])
  }
}

///|
/// Visit sequences, itemsets and labels in input order before canonicalizing.
/// Duplicate labels within an itemset collapse; itemset and sequence positions
/// remain intact. Empty sequences are allowed; empty itemsets are rejected.
pub fn encode_labeled_sequences(
  sequences : Array[Array[Array[String]]],
) -> (Database, LabelDictionary) raise MiningError {
  let dictionary = label_dictionary()
  let encoded : Array[Array[Array[Int32]]] = []
  for sequence_index, sequence in sequences {
    let events : Array[Array[Int32]] = []
    for event_index, event in sequence {
      if event.is_empty() {
        raise Invalid(
          "empty labeled itemset at sequence \{sequence_index}, itemset \{event_index}",
        )
      }
      let items : Array[Int32] = []
      for label in event {
        items.push(intern_label(dictionary, label))
      }
      events.push(items)
    }
    encoded.push(events)
  }
  (database(encoded), dictionary)
}

///|
/// Decode into fresh arrays in canonical ID order, which may differ from label
/// order in the original input. The supplied dictionary must cover every ID;
/// dictionaries carry no identity token, so callers must retain the right one.
pub fn decode_labeled_sequences(
  db : Database,
  dictionary : LabelDictionary,
) -> Array[Array[Array[String]]] raise MiningError {
  validate_database(db)
  let decoded : Array[Array[Array[String]]] = []
  for sequence_index, sequence in db.sequences {
    let events : Array[Array[String]] = []
    for event_index, event in sequence {
      let labels : Array[String] = []
      for id in event {
        match label_of(dictionary, id) {
          Some(label) => labels.push(label)
          None =>
            raise Invalid(
              "unknown label ID \{id} at sequence \{sequence_index}, itemset \{event_index}",
            )
        }
      }
      events.push(labels)
    }
    decoded.push(events)
  }
  decoded
}
