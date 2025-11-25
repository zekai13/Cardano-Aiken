use aiken/builtin.{Data, ByteArray}
use aiken/collection/list
use cardano/transaction.{ScriptContext}

pub fn check_owner(owner: ByteArray, context: ScriptContext) -> Bool {
  list.any(context.transaction.extra_signatories, fn(sig) { sig == owner })
}

pub fn main(datum: Data, _redeemer: Data, context: ScriptContext) -> Bool {
  when datum is {
    Data::Bytes(owner_hash) -> check_owner(owner_hash, context)
    _ -> False
  }
}
