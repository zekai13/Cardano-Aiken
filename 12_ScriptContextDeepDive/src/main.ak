use aiken/builtin.{Data, ByteArray}
use aiken/collection/list
use cardano/transaction.{ScriptContext, TxOutput}
use cardano/value

/// 检查 outputs 是否存在发往指定地址的 UTxO。
pub fn has_output_to(address: ByteArray, outputs: List(TxOutput)) -> Bool {
  list.any(outputs, fn(output) { output.address == address })
}

/// 计算交易额外签名者数量。
pub fn signer_count(context: ScriptContext) -> Int {
  list.length(context.transaction.extra_signatories)
}

/// 读取 minted map 中某资产的增减量（正数=铸造，负数=销毁）。
pub fn minted_amount(policy_id: ByteArray, token: ByteArray, context: ScriptContext) -> Int {
  value.amount_of(context.transaction.mint, policy_id, token)
}

/// 是否携带任何 reference inputs。
pub fn has_reference_inputs(context: ScriptContext) -> Bool {
  list.length(context.reference_inputs) > 0
}

/// 检查所有输出是否都至少携带指定数量的 ADA（policyId 与 tokenName 为空字节）。
pub fn outputs_have_min_ada(min_ada: Int, outputs: List(TxOutput)) -> Bool {
  list.all(outputs, fn(output) { value.amount_of(output.value, #[], #[]) >= min_ada })
}

/// reference inputs 的数量是否不超过限制。
pub fn reference_inputs_within(limit: Int, context: ScriptContext) -> Bool {
  list.length(context.reference_inputs) <= limit
}

/// 演示组合校验：根据 Redeemer 类型走不同路径。
pub fn main(_datum: Data, redeemer: Data, context: ScriptContext) -> Bool {
  when redeemer is {
    // 路径1：Bytes -> 仅检查 outputs 里有目标地址
    Data::Bytes(target) ->
      has_output_to(target, context.transaction.outputs)

    // 路径2：列表 [policy, token, amount] -> 校验 minted 量
    Data::List([Data::Bytes(policy), Data::Bytes(token), Data::Integer(expected)]) ->
      minted_amount(policy, token, context) == expected

    // 路径3：整数 -> 检查所有输出的最小 ADA
    Data::Integer(min_ada) ->
      outputs_have_min_ada(min_ada, context.transaction.outputs)

    // 其他：至少需要 1 个签名，且引用输入数量在限制内
    _ ->
      signer_count(context) > 0 && reference_inputs_within(0, context)
  }
}
