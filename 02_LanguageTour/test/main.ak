use aiken/collection/list
use aiken/test
use cardano_aiken/lesson02.{average, classify, clamp, describe, greet, greet_with_default, sum_positive, Message}

test fn greet_person() {
  expect "Hello, Alice" = greet("Alice")
}

test fn greet_fallback() {
  expect "Hello, Anonymous" = greet_with_default(None)
}

test fn clamp_in_range() {
  expect 10 = clamp(10, 0, 20)
  expect 0 = clamp(-5, 0, 20)
  expect 20 = clamp(25, 0, 20)
}

test fn describe_message() {
  expect "PONG" = describe(Message::Ping)
}

test fn classify_signs() {
  expect "negative" = classify(-1)
  expect "zero" = classify(0)
  expect "positive" = classify(7)
}

test fn average_and_sum() {
  let values = [1, 2, 3, -5, 6]

  expect Some(1) = average(values)
  expect 12 = sum_positive(values)
}
