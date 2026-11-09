///|
test "item counts stay exact beyond Int32 with shared valid arrays" {
  let event = Array::makei(65536, fn(i) { i })
  let p : @moonseqmine.Pattern = {
    itemsets: Array::makei(32768, fn(_) { event }),
  }
  assert_eq(@moonseqmine.item_count(p), 2147483648L)
}
