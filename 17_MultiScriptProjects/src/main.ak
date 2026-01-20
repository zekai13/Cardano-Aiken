use aiken/builtin.{Data}
use aiken/collection/list
use cardano/value
use cardano/transaction.{ScriptContext}

pub type ScriptKind {
  Spending
  Minting
  Governance
}

pub fn spend_handler(datum: Data, redeemer: Data, _context: ScriptContext) -> Bool {
  match { datum, redeemer } {
    {Data::Bytes(owner), Data::Bytes(sig)} -> owner == sig
    _ -> False
  }
}

pub fn mint_handler(redeemer: Data, context: ScriptContext) -> Bool {
  when redeemer is {
    Data::List([Data::Bytes(policy), Data::Bytes(token), Data::Integer(amount)]) ->
      value.amount_of(context.transaction.mint, policy, token) == amount
    _ -> False
  }
}

pub fn governance_handler(_datum: Data, redeemer: Data, context: ScriptContext) -> Bool {
  // 极简示例：要求至少两个签名者，且 redeemer = Bytes("vote")
  list.length(context.transaction.extra_signatories) >= 2
    && redeemer == Data::Bytes(#"vote")
}

pub fn route(kind: ScriptKind, datum: Data, redeemer: Data, context: ScriptContext) -> Bool {
  when kind is {
    Spending -> spend_handler(datum, redeemer, context)
    Minting -> mint_handler(redeemer, context)
    Governance -> governance_handler(datum, redeemer, context)
  }
}
