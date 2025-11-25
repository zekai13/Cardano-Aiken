use aiken/test
use cardano_aiken/lesson04/helpers.{average}

test fn average_positive() {
  expect Some(2) = average([1, 2, 3])
}
