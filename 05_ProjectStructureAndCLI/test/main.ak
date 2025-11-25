use aiken/builtin.{Data}
use aiken/test
use cardano_aiken/lesson05.{main}

test fn always_true() {
  let dummy = Data::Bytes(#[])
  expect True = main(dummy, dummy, dummy)
}
