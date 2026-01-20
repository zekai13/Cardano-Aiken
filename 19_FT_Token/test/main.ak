use aiken/builtin.{Data, ByteArray}
use aiken/test
use cardano/transaction
use cardano/value
use cardano_aiken/lesson19

fn tx_with_mint(policy: ByteArray, token: ByteArray, amount: Int, signers: List(ByteArray)) -> transaction::Transaction {
  let minted = value::add_asset(value::zero(), policy, token, amount)

  transaction::Transaction {
    extra_signatories: signers,
    mint: minted,
    ..transaction::Transaction::default()
  }
}

fn redeemer(owner: ByteArray, token: ByteArray, cap: Int) -> Data {
  Data::List([Data::Bytes(owner), Data::Bytes(token), Data::Integer(cap)])
}

test fn decode_redeemer_triplet() {
  expect Some(lesson19::FTConfig { owner: #"owner", token: #"FT", cap: 100 }) =
    lesson19::decode_redeemer(redeemer(#"owner", #"FT", 100))
}

test fn allows_owner_mint_under_cap() {
  let policy = #"policy"
  let token = #"FT"
  let tx = tx_with_mint(policy, token, 50, [#"owner"])
  expect True = lesson19::main(redeemer(#"owner", token, 100), policy, tx)
}

test fn blocks_without_owner_signature() {
  let policy = #"policy"
  let token = #"FT"
  let tx = tx_with_mint(policy, token, 50, [])
  expect False = lesson19::main(redeemer(#"owner", token, 100), policy, tx)
}

test fn blocks_over_cap() {
  let policy = #"policy"
  let token = #"FT"
  let tx = tx_with_mint(policy, token, 150, [#"owner"])
  expect False = lesson19::main(redeemer(#"owner", token, 100), policy, tx)
}
