use aiken/builtin.{Data}
use aiken/test
use cardano/transaction
use cardano_aiken/lesson07.{main}

fn dummy_context(extra: List(ByteArray)) -> transaction::ScriptContext {
  transaction::ScriptContext {
    purpose: transaction::ScriptPurpose::Spend(transaction::OutputReference::new(transaction::TxId(#[]), 0)),
    script_hash: #[],
    transaction: transaction::Transaction {
      extra_signatories: extra,
      ..transaction::Transaction::default()
    }
  }
}

test fn requires_signer() {
  let ctx = dummy_context([#[]])
  expect True = main(Data::Bytes(#[]), Data::Bytes(#[]), ctx)
}

test fn fails_without_signer() {
  let ctx = dummy_context([])
  expect False = main(Data::Bytes(#[]), Data::Bytes(#[]), ctx)
}
