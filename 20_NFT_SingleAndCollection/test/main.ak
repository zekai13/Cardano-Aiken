use aiken/builtin.{Data}
use aiken/test
use cardano/transaction
use cardano/value
use cardano_aiken/lesson20

fn tx_with_mint(policy: ByteArray, token: ByteArray, amount: Int, signers: List(ByteArray)) -> transaction::Transaction {
  let minted = value::add_asset(value::zero(), policy, token, amount)

  transaction::Transaction {
    extra_signatories: signers,
    mint: minted,
    ..transaction::Transaction::default()
  }
}

test fn single_mint_allows_owner_and_one_token() {
  let policy = #"policy"
  let token = #"MyNFT"
  let tx = tx_with_mint(policy, token, 1, [#"owner"])
  let redeemer = Data::List([Data::Bytes(#"owner"), Data::Bytes(token)])
  expect True = lesson20::main_single(redeemer, policy, tx)
}

test fn single_mint_blocks_wrong_amount() {
  let policy = #"policy"
  let token = #"MyNFT"
  let tx = tx_with_mint(policy, token, 2, [#"owner"])
  let redeemer = Data::List([Data::Bytes(#"owner"), Data::Bytes(token)])
  expect False = lesson20::main_single(redeemer, policy, tx)
}

test fn collection_allows_within_max_and_one_mint() {
  let policy = #"policy"
  let prefix = #"ART#"
  let idx = 5
  let token = prefix + value::int_to_bytes(idx)
  let tx = tx_with_mint(policy, token, 1, [#"owner"])
  let redeemer = Data::List([Data::Bytes(#"owner"), Data::Bytes(prefix), Data::Integer(idx), Data::Integer(10)])
  expect True = lesson20::main_collection(redeemer, policy, tx)
}

test fn collection_blocks_over_max() {
  let policy = #"policy"
  let prefix = #"ART#"
  let idx = 11
  let token = prefix + value::int_to_bytes(idx)
  let tx = tx_with_mint(policy, token, 1, [#"owner"])
  let redeemer = Data::List([Data::Bytes(#"owner"), Data::Bytes(prefix), Data::Integer(idx), Data::Integer(10)])
  expect False = lesson20::main_collection(redeemer, policy, tx)
}

test fn collection_blocks_without_owner_signature() {
  let policy = #"policy"
  let prefix = #"ART#"
  let idx = 1
  let token = prefix + value::int_to_bytes(idx)
  let tx = tx_with_mint(policy, token, 1, [])
  let redeemer = Data::List([Data::Bytes(#"owner"), Data::Bytes(prefix), Data::Integer(idx), Data::Integer(10)])
  expect False = lesson20::main_collection(redeemer, policy, tx)
}
