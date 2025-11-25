use aiken/test
use cardano_aiken/lesson06.{add, is_even}

test fn add_numbers() {
  expect 4 = add(2, 2)
}

test fn check_even() {
  expect True = is_even(4)
  expect False = is_even(5)
}
