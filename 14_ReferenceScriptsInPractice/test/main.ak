use aiken/builtin.{Data, ByteArray}
use aiken/test
use cardano/transaction
use cardano_aiken/lesson14

fn ctx_with_signers(signers: List(ByteArray)) -> transaction::ScriptContext {
  transaction::ScriptContext {
    purpose: transaction::ScriptPurpose::Spend(transaction::OutputReference::new(transaction::TxId(#[]), 0)),
    script_hash: #[],
    transaction: transaction::Transaction {
      extra_signatories: signers,
      ..transaction::Transaction::default()
    }
  }
}

test fn rejects_without_signer() {
  let ctx = ctx_with_signers([])
  expect False = lesson14::main(Data::Bytes(#""), Data::Bytes(#"ref-ok"), ctx)
}

test fn accepts_with_signer_and_flag() {
  let ctx = ctx_with_signers([#"sig"])
  expect True = lesson14::main(Data::Bytes(#""), Data::Bytes(#"ref-ok"), ctx)
}

test fn accepts_fallback_with_signer() {
  let ctx = ctx_with_signers([#"sig"])
  expect True = lesson14::main(Data::Bytes(#""), Data::Integer(42), ctx)
}
