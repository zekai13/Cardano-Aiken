use aiken/builtin.{Data, ByteArray}
use aiken/collection/list
use cardano/value
use cardano/transaction.{Transaction}

pub type SingleConfig {
  SingleConfig {
    owner: ByteArray
    token: ByteArray
  }
}

pub type CollectionConfig {
  CollectionConfig {
    owner: ByteArray
    prefix: ByteArray
    max_size: Int
  }
}

/// Redeemer for single NFT: [owner, token]
pub fn decode_single(redeemer: Data) -> Option(SingleConfig) {
  when redeemer is {
    Data::List([Data::Bytes(owner), Data::Bytes(token)]) ->
      Some(SingleConfig { owner, token })
    _ -> None
  }
}

/// Redeemer for collection mint: [owner, prefix, index, max_size]
pub fn decode_collection(redeemer: Data) -> Option(CollectionConfig, Int) {
  when redeemer is {
    Data::List([Data::Bytes(owner), Data::Bytes(prefix), Data::Integer(idx), Data::Integer(max_size)]) ->
      Some(CollectionConfig { owner, prefix, max_size }, idx)
    _ -> None
  }
}

pub fn signer_is_owner(owner: ByteArray, tx: Transaction) -> Bool {
  list.any(tx.extra_signatories, fn(sig) { sig == owner })
}

pub fn minted_amount(policy_id: ByteArray, token: ByteArray, tx: Transaction) -> Int {
  value.amount_of(tx.mint, policy_id, token)
}

/// Enforce exactly one token minted once (amount == 1).
pub fn enforce_single(config: SingleConfig, policy_id: ByteArray, tx: Transaction) -> Bool {
  signer_is_owner(config.owner, tx)
    && minted_amount(policy_id, config.token, tx) == 1
}

/// Enforce collection: prefix ++ index as asset name, total <= max_size, mint exactly 1.
pub fn enforce_collection(config: CollectionConfig, index: Int, policy_id: ByteArray, tx: Transaction) -> Bool {
  let token = config.prefix + value.int_to_bytes(index)
  let minted = minted_amount(policy_id, token, tx)

  signer_is_owner(config.owner, tx)
    && index >= 0
    && index < config.max_size
    && minted == 1
}

pub fn main_single(redeemer: Data, policy_id: ByteArray, tx: Transaction) -> Bool {
  when decode_single(redeemer) is {
    Some(cfg) -> enforce_single(cfg, policy_id, tx)
    None -> False
  }
}

pub fn main_collection(redeemer: Data, policy_id: ByteArray, tx: Transaction) -> Bool {
  when decode_collection(redeemer) is {
    Some({cfg, idx}) -> enforce_collection(cfg, idx, policy_id, tx)
    None -> False
  }
}
