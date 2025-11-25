use aiken/test
use cardano_aiken/lesson09.{CounterDatum, CounterRedeemer, apply}

test fn increment_counter() {
  let datum = CounterDatum { version: 1, value: 5 }
  expect CounterDatum { version: 1, value: 6 } = apply(datum, CounterRedeemer::Increment)
}

test fn reset_counter() {
  let datum = CounterDatum { version: 1, value: 5 }
  expect CounterDatum { version: 2, value: 0 } = apply(datum, CounterRedeemer::Reset)
}
