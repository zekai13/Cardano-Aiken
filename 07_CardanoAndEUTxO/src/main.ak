use aiken/builtin.{Data}
use aiken/collection/list
use cardano/transaction.{ScriptContext}

/// 演示如何读取交易中的签名者数量。
pub fn main(_datum: Data, _redeemer: Data, context: ScriptContext) -> Bool {
  let signers = context.transaction.extra_signatories

  list.length(signers) > 0
}
