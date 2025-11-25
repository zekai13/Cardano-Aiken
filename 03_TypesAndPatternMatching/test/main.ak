use aiken/test
use cardano_aiken/lesson03.{label, next, OrderStatus}

test fn label_states() {
  expect "Waiting" = label(OrderStatus::Draft)
  expect "Alice offers 42" = label(OrderStatus::Active { buyer: "Alice", price: 42 })
}

test fn next_transitions() {
  expect OrderStatus::Active { buyer: "TODO", price: 0 } = next("activate", OrderStatus::Draft)
  expect OrderStatus::Cancelled("manual") = next("cancel", OrderStatus::Draft)
}
