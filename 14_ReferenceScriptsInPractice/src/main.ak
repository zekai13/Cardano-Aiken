use aiken/builtin.{Data}
use aiken/collection/list
use cardano/transaction.{ScriptContext}

/// 判断交易是否由至少一个签名者发起。
pub fn has_signer(context: ScriptContext) -> Bool {
  list.length(context.transaction.extra_signatories) > 0
}

/// 允许的 redeemer：Bytes("ref-ok")，或默认放行。
pub fn main(_datum: Data, redeemer: Data, context: ScriptContext) -> Bool {
  when redeemer is {
    Data::Bytes(bytes) -> bytes == #"ref-ok" && has_signer(context)
    _ -> has_signer(context)
  }
}
