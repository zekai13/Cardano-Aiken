use aiken/builtin.{Data}
use aiken/result
use aiken/test
use cardano/transaction
use cardano_aiken/lesson18

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

test fn owner_and_positive_and_after_passes() {
  let ctx = ctx_with_signers([#"owner"])
  expect Ok(()) = lesson18::validate(#"owner", 10, True, ctx)
}

test fn fails_when_not_owner() {
  let ctx = ctx_with_signers([#"other"])
  expect Error(lesson18::Error::NotOwner) = lesson18::validate(#"owner", 10, True, ctx)
}

test fn fails_when_amount_non_positive() {
  let ctx = ctx_with_signers([#"owner"])
  expect Error(lesson18::Error::InvalidAmount) = lesson18::validate(#"owner", 0, True, ctx)
}

test fn fails_when_too_early() {
  let ctx = ctx_with_signers([#"owner"])
  expect Error(lesson18::Error::TooEarly) = lesson18::validate(#"owner", 10, False, ctx)
}
