use aiken/builtin.{Data, ByteArray}
use aiken/test
use cardano/assets.{PolicyId}
use cardano/transaction
use cardano_aiken/lesson11

fn mint_tx(owner: ByteArray, signed: Bool) -> transaction::Transaction {
  let signers = when signed is { True -> [owner] False -> [] }

  transaction::Transaction {
    extra_signatories: signers,
    ..transaction::Transaction::default()
  }
}

fn redeemer(owner: ByteArray, token: ByteArray, amount: Int) -> Data {
  Data::List([Data::Bytes(owner), Data::Bytes(token), Data::Integer(amount)])
}

test fn decode_redeemer_triplet() {
  let args = redeemer(#"owner", #"MyToken", 100)
  expect Some(lesson11::MintConfig { owner: #"owner", token_name: #"MyToken", amount: 100 }) =
    lesson11::decode_redeemer(args)
}

test fn allows_owner_when_amount_matches() {
  let policy_id: PolicyId = #"abcd"
  let owner = #"deadbeef"
  let tx = mint_tx(owner, True)
  expect True = lesson11::main(redeemer(owner, #"MyToken", 0), policy_id, tx)
}

test fn blocks_without_owner_signature() {
  let policy_id: PolicyId = #"abcd"
  let owner = #"deadbeef"
  let tx = mint_tx(owner, False)
  expect False = lesson11::main(redeemer(owner, #"MyToken", 0), policy_id, tx)
}

test fn blocks_wrong_amount() {
  let policy_id: PolicyId = #"abcd"
  let owner = #"deadbeef"
  let tx = mint_tx(owner, True)
  expect False = lesson11::main(redeemer(owner, #"MyToken", 50), policy_id, tx)
}
