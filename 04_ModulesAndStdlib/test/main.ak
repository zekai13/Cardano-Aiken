use aiken/test
use cardano_aiken/lesson04/helpers.{average, median}

test fn average_positive() {
  expect Some(2) = average([1, 2, 3])
}

test fn median_basic() {
  expect Some(3) = median([1, 2, 3, 4, 5])
}
