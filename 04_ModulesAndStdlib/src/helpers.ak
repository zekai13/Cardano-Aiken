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
