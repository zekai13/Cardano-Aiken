use aiken/builtin.{Data, ByteArray}
use aiken/collection/list
use cardano/transaction.{Transaction}
use cardano/value

pub type FTConfig {
  FTConfig {
    owner: ByteArray
    token: ByteArray
    cap: Int
  }
}

pub fn decode_redeemer(redeemer: Data) -> Option(FTConfig) {
  when redeemer is {
    Data::List([Data::Bytes(owner), Data::Bytes(token), Data::Integer(cap)]) ->
      Some(FTConfig { owner, token, cap })
    _ ->
      None
  }
}

pub fn signer_is_owner(owner: ByteArray, tx: Transaction) -> Bool {
  list.any(tx.extra_signatories, fn(sig) { sig == owner })
}

pub fn minted_amount(policy_id: ByteArray, token: ByteArray, tx: Transaction) -> Int {
  value.amount_of(tx.mint, policy_id, token)
}

pub fn validate(config: FTConfig, policy_id: ByteArray, tx: Transaction) -> Bool {
  let minted = minted_amount(policy_id, config.token, tx)

  signer_is_owner(config.owner, tx)
    && minted > 0
    && minted <= config.cap
}

/// Minting Policy 入口：Redeemer=[owner, token, cap]，PolicyId 由 context 传入。
pub fn main(redeemer: Data, policy_id: ByteArray, tx: Transaction) -> Bool {
  when decode_redeemer(redeemer) is {
    Some(config) -> validate(config, policy_id, tx)
    None -> False
  }
}
