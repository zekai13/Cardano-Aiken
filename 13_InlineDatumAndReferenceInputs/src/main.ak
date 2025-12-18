use aiken/builtin.{Data, ByteArray}
use aiken/collection/list
use cardano/transaction.{Input, ScriptContext}

/// 收集引用输入里所有 inline datum。
pub fn reference_inline_datums(context: ScriptContext) -> List(Data) {
  list.filter_map(context.transaction.reference_inputs, fn(input) { input.resolved.datum })
}

/// 判断单个 datum 是否包含目标 owner（可直接 Bytes，也可在列表里）。
fn datum_has_owner(datum: Data, owner: ByteArray) -> Bool {
  when datum is {
    Data::Bytes(bytes) -> bytes == owner
    Data::List(items) ->
      list.any(items, fn(item) {
        when item is {
          Data::Bytes(bytes) -> bytes == owner
          _ -> False
        }
      })
    _ -> False
  }
}

/// 判断引用输入中是否包含指定 owner 的 inline datum。
pub fn has_owner_in_reference(owner: ByteArray, context: ScriptContext) -> Bool {
  list.any(reference_inline_datums(context), fn(datum) {
    datum_has_owner(datum, owner)
  })
}

/// 从引用输入中解析第一个整数阈值（若不存在整数 datum 返回 None）。
pub fn threshold_from_reference(context: ScriptContext) -> Option(Int) {
  list.first(list.filter_map(reference_inline_datums(context), fn(datum) {
    when datum is {
      Data::Integer(threshold) -> Some(threshold)
      _ -> None
    }
  }))
}

/// 引用输入数量是否达到要求。
pub fn reference_count_at_least(min_refs: Int, context: ScriptContext) -> Bool {
  list.length(context.transaction.reference_inputs) >= min_refs
}

/// 引用输入中的 ADA（lovelace）是否都不小于给定值。
pub fn reference_min_ada_at_least(min_ada: Int, context: ScriptContext) -> Bool {
  list.all(context.transaction.reference_inputs, fn(input) {
    value.amount_of(input.resolved.value, #[], #[]) >= min_ada
  })
}

/// 演示三种路径：
/// - Redeemer Bytes：检查引用输入中是否有目标 owner 的 inline datum。
/// - Redeemer List([owner, min_ada])：要求引用输入中包含该 owner 且 ADA 足够。
/// - Redeemer Integer：要求至少有 N 个引用输入。
/// - 其他：只要存在任意 inline datum 即通过。
pub fn main(_datum: Data, redeemer: Data, context: ScriptContext) -> Bool {
  when redeemer is {
    Data::List([Data::Bytes(owner), Data::Integer(min_ada)]) ->
      has_owner_in_reference(owner, context) && reference_min_ada_at_least(min_ada, context)
    Data::Bytes(owner) -> has_owner_in_reference(owner, context)
    Data::Integer(min_refs) -> reference_count_at_least(min_refs, context)
    _ -> list.length(reference_inline_datums(context)) > 0
  }
}
