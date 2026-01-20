use aiken/builtin.{Data}
use aiken/test
use cardano/time
use cardano/transaction
use cardano_aiken/lesson16

fn ctx_with_range(start: Int, end: Int) -> transaction::ScriptContext {
  transaction::ScriptContext {
    purpose: transaction::ScriptPurpose::Spend(transaction::OutputReference::new(transaction::TxId(#[]), 0)),
    script_hash: #[],
    transaction: transaction::Transaction {
      valid_range: time.from_slots(start, end),
      ..transaction::Transaction::default()
    }
  }
}

test fn after_passes_when_range_starts_at_deadline() {
  let ctx = ctx_with_range(100, 200)
  expect True = lesson16::main(Data::Constr(0, []), Data::Integer(100), ctx)
}

test fn after_fails_when_before_deadline() {
  let ctx = ctx_with_range(50, 99)
  expect False = lesson16::main(Data::Constr(0, []), Data::Integer(100), ctx)
}

test fn between_passes_inside_range() {
  let ctx = ctx_with_range(100, 200)
  expect True = lesson16::main(Data::Constr(0, []), Data::List([Data::Integer(120), Data::Integer(180)]), ctx)
}

test fn between_fails_when_outside_range() {
  let ctx = ctx_with_range(100, 150)
  expect False = lesson16::main(Data::Constr(0, []), Data::List([Data::Integer(120), Data::Integer(180)]), ctx)
}
