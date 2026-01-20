use aiken/builtin.{Data, ByteArray}
use aiken/test
use cardano/transaction
use cardano/value
use cardano_aiken/lesson17

fn ctx_with(signers: List(ByteArray), mint: value::Value) -> transaction::ScriptContext {
  transaction::ScriptContext {
    purpose: transaction::ScriptPurpose::Spend(transaction::OutputReference::new(transaction::TxId(#[]), 0)),
    script_hash: #[],
    transaction: transaction::Transaction {
      extra_signatories: signers,
      mint,
      ..transaction::Transaction::default()
    }
  }
}

test fn spend_handler_requires_matching_owner() {
  let ctx = ctx_with([], value::zero())
  expect True = lesson17::spend_handler(Data::Bytes(#"alice"), Data::Bytes(#"alice"), ctx)
  expect False = lesson17::spend_handler(Data::Bytes(#"alice"), Data::Bytes(#"bob"), ctx)
}

test fn mint_handler_checks_amount_of() {
  let policy = #"policy"
  let token = #"TKN"
  let minted = value::lovelace(0)
  let with_token = value::add_asset(minted, policy, token, 100)
  let ctx = ctx_with([], with_token)
  expect True = lesson17::mint_handler(Data::List([Data::Bytes(policy), Data::Bytes(token), Data::Integer(100)]), ctx)
  expect False = lesson17::mint_handler(Data::List([Data::Bytes(policy), Data::Bytes(token), Data::Integer(50)]), ctx)
}

test fn governance_requires_two_signers_and_vote() {
  let ctx_ok = ctx_with([#"sig1", #"sig2"], value::zero())
  let ctx_bad = ctx_with([#"sig1"], value::zero())
  expect True = lesson17::governance_handler(Data::Constr(0, []), Data::Bytes(#"vote"), ctx_ok)
  expect False = lesson17::governance_handler(Data::Constr(0, []), Data::Bytes(#"vote"), ctx_bad)
}

test fn route_dispatches_to_handlers() {
  let ctx = ctx_with([#"sig1", #"sig2"], value::add_asset(value::zero(), #"p", #"t", 10))
  expect True = lesson17::route(lesson17::ScriptKind::Spending, Data::Bytes(#"a"), Data::Bytes(#"a"), ctx)
  expect True = lesson17::route(lesson17::ScriptKind::Minting, Data::Constr(0, []), Data::List([Data::Bytes(#"p"), Data::Bytes(#"t"), Data::Integer(10)]), ctx)
}
