use aiken/builtin.{Data, ByteArray}
use aiken/test
use cardano/transaction
use cardano_aiken/lesson10.{check_owner}

fn ctx_with_signer(owner: ByteArray) -> transaction::ScriptContext {
  transaction::ScriptContext {
    purpose: transaction::ScriptPurpose::Spend(transaction::OutputReference::new(transaction::TxId(#[]), 0)),
    script_hash: #[],
    transaction: transaction::Transaction {
      extra_signatories: [owner],
      ..transaction::Transaction::default()
    }
  }
}

test fn owner_check_passes() {
  let ctx = ctx_with_signer(#"abcd")
  expect True = check_owner(#"abcd", ctx)
}

test fn owner_check_blocks() {
  let ctx = ctx_with_signer(#"abcd")
  expect False = check_owner(#"ffff", ctx)
}
