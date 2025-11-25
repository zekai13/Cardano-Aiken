use aiken/builtin.{Data}
use cardano/transaction.{ScriptContext}
use cardano_aiken/lesson10.{check_owner}

validator owner_guard {
  spend(datum: Data, _redeemer: Data, context: ScriptContext) {
    when datum is {
      Data::Bytes(owner_hash) -> check_owner(owner_hash, context)
      _ -> False
    }
  }
}
