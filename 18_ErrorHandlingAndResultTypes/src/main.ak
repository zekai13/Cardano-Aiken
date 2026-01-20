use aiken/collection/list
use aiken/result
use cardano/transaction.{ScriptContext}

pub type Error {
  NotOwner
  InvalidAmount
  TooEarly
}

pub fn ensure_owner(is_owner: Bool) -> Result((), Error) {
  if is_owner { Ok(()) } else { Error(NotOwner) }
}

pub fn ensure_signed_by(owner: ByteArray, context: ScriptContext) -> Result((), Error) {
  if list.any(context.transaction.extra_signatories, fn(sig) { sig == owner }) {
    Ok(())
  } else {
    Error(NotOwner)
  }
}

pub fn ensure_positive(amount: Int) -> Result((), Error) {
  if amount > 0 { Ok(()) } else { Error(InvalidAmount) }
}

pub fn ensure_after(deadline_passed: Bool) -> Result((), Error) {
  if deadline_passed { Ok(()) } else { Error(TooEarly) }
}

/// 组合校验：签名 -> 金额 -> 时间
pub fn validate(owner: ByteArray, amount: Int, deadline_passed: Bool, context: ScriptContext) -> Result((), Error) {
  ensure_signed_by(owner, context)
    |> result.and_then(fn(_) { ensure_positive(amount) })
    |> result.and_then(fn(_) { ensure_after(deadline_passed) })
}
