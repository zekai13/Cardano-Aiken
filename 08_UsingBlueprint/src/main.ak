use aiken/builtin.{ByteArray}
use aiken/collection/list
use cardano/transaction.{ScriptContext}

/// 参数化的 owner-only 验证逻辑，便于 blueprint 应参。
pub fn owner_only(owner: ByteArray, context: ScriptContext) -> Bool {
  list.any(context.transaction.extra_signatories, fn(signer) { signer == owner })
}
