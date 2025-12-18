use aiken/builtin.{Data, ByteArray}
use aiken/test
use cardano/transaction
use cardano_aiken/lesson12

fn ctx_with(outputs: List(transaction::TxOutput), signers: List(ByteArray)) -> transaction::ScriptContext {
  transaction::ScriptContext {
    purpose: transaction::ScriptPurpose::Spend(transaction::OutputReference::new(transaction::TxId(#[]), 0)),
    script_hash: #[],
    transaction: transaction::Transaction {
      outputs,
      extra_signatories: signers,
      reference_inputs: [],
      ..transaction::Transaction::default()
    }
  }
}

fn output_to(address: ByteArray) -> transaction::TxOutput {
  transaction::TxOutput { address, ..transaction::TxOutput::default() }
}

fn minted_redeemer(policy: ByteArray, token: ByteArray, amount: Int) -> Data {
  Data::List([Data::Bytes(policy), Data::Bytes(token), Data::Integer(amount)])
}

test fn finds_output_by_address() {
  let target = #"abcd"
  let outputs = [output_to(target)]
  let ctx = ctx_with(outputs, [])
  expect True = lesson12::main(Data::Bytes(target), Data::Bytes(target), ctx)
}

test fn minted_amount_defaults_to_zero() {
  let ctx = ctx_with([], [])
  let redeemer = minted_redeemer(#"policy", #"asset", 0)
  expect True = lesson12::main(Data::Bytes(#""), redeemer, ctx)
}

test fn min_ada_branch_fails_when_insufficient() {
  let outputs = [transaction::TxOutput::default()]
  let ctx = ctx_with(outputs, [])
  expect False = lesson12::main(Data::Bytes(#""), Data::Integer(2_000_000), ctx)
}

test fn min_ada_branch_passes_for_zero_requirement() {
  let outputs = [transaction::TxOutput::default()]
  let ctx = ctx_with(outputs, [])
  expect True = lesson12::main(Data::Bytes(#""), Data::Integer(0), ctx)
}

test fn fallback_requires_signer_and_no_refs() {
  let ctx = ctx_with([], [#"sig"])
  expect True = lesson12::main(Data::Bytes(#""), Data::Integer(42), ctx)
}
