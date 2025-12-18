use aiken/builtin.{Data, ByteArray}
use aiken/collection/list
use cardano/assets.{PolicyId}
use cardano/transaction.{Transaction}
use cardano/value

pub type MintConfig {
  MintConfig {
    owner: ByteArray
    token_name: ByteArray
    amount: Int
  }
}

pub fn decode_redeemer(redeemer: Data) -> Option(MintConfig) {
  when redeemer is {
    Data::List([Data::Bytes(owner), Data::Bytes(token), Data::Integer(amount)]) ->
      Some(MintConfig { owner, token_name: token, amount })
    _ ->
      None
  }
}

pub fn signer_is_owner(owner: ByteArray, tx: Transaction) -> Bool {
  list.any(tx.extra_signatories, fn(sig) { sig == owner })
}

pub fn minted_by_policy(policy_id: PolicyId, token: ByteArray, tx: Transaction) -> Int {
  value.amount_of(tx.mint, policy_id, token)
}

pub fn validate(config: MintConfig, policy_id: PolicyId, tx: Transaction) -> Bool {
  signer_is_owner(config.owner, tx)
    && minted_by_policy(policy_id, config.token_name, tx) == config.amount
}

pub fn main(redeemer: Data, policy_id: PolicyId, tx: Transaction) -> Bool {
  when decode_redeemer(redeemer) is {
    Some(config) -> validate(config, policy_id, tx)
    None -> False
  }
}
