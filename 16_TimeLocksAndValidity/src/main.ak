use aiken/builtin.{Data, Int}
use cardano/time
use cardano/transaction.{ScriptContext}

/// 检查 valid_range 是否“在 deadline 之后”（闭区间）。
pub fn after(deadline: Int, context: ScriptContext) -> Bool {
  time.contains_from(context.transaction.valid_range, deadline)
}

/// 检查 valid_range 是否落在 [start, end] 区间内（含端点）。
pub fn between(start: Int, end: Int, context: ScriptContext) -> Bool {
  time.contains(context.transaction.valid_range, time.from_slots(start, end))
}

/// Redeemer:
/// - Integer(deadline): 检查 `after(deadline)`
/// - List([start, end]): 检查 `between(start, end)`
pub fn main(_datum: Data, redeemer: Data, context: ScriptContext) -> Bool {
  when redeemer is {
    Data::Integer(deadline) -> after(deadline, context)
    Data::List([Data::Integer(start), Data::Integer(end)]) -> between(start, end, context)
    _ -> False
  }
}
