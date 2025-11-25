use aiken/collection/list

pub fn average(values: List(Int)) -> Option(Int) {
  let total = list.fold(values, 0, fn(acc, v) { acc + v })
  let count = list.length(values)

  if count == 0 {
    None
  } else {
    Some(total / count)
  }
}

pub fn median(values: List(Int)) -> Option(Int) {
  let sorted = list.sort(values, fn(a, b) { a <= b })
  let len = list.length(sorted)
  if len == 0 {
    None
  } else {
    let mid = len / 2
    Some(sorted[mid])
  }
}
