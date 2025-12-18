# 12 · Script Context Deep Dive

> 拆解 `ScriptContext` 的常用字段：inputs/outputs、signers、minted、reference inputs。用小 helper 组合出多种校验路径。

---

## 学习目标
1. 熟悉 `ScriptContext` 中的核心字段：`transaction.outputs`、`transaction.extra_signatories`、`transaction.mint`、`reference_inputs`。
2. 学会用 `value.amount_of` 读取 `mint` 中指定资产的增减量。
3. 编写针对 helper 的单元测试，验证输出搜索、签名数、minted 读取的行为。

## 开始前贴士
| 步骤 | 命令/动作 | 说明 |
| --- | --- | --- |
| 打开目录 | `cd /Users/zekai/Documents/Cardano/Cardano-Aiken/12_ScriptContextDeepDive` | |
| 编译 & 测试 | `aiken check` | 会运行 `test/` 里的断言 |
| 构建 blueprint（无验证器时可略过） | `aiken build --trace-level verbose` | 若没有 validator，出现“no validators”提示属正常 |

## 本讲文件速览
| 文件/目录 | 作用 |
| --- | --- |
| `README.md` | 本讲讲义、命令示例、练习与 Troubleshooting。 |
| `aiken.toml` | 声明包名 `cardano_aiken/lesson12`、Plutus 版本。 |
| `src/main.ak` | Helper：输出搜索、签名计数、minted 读取、reference inputs 判断、最小 ADA 检查；`main` 演示四条校验分支。 |
| `test/main.ak` | 构造 dummy context，验证 helper 的行为。 |

---

## 1. 拆解 ScriptContext

`src/main.ak`
```gleam
use aiken/builtin.{Data, ByteArray}
use aiken/collection/list
use cardano/transaction.{ScriptContext, TxOutput}
use cardano/value

pub fn has_output_to(address: ByteArray, outputs: List(TxOutput)) -> Bool {
  list.any(outputs, fn(output) { output.address == address })
}

pub fn signer_count(context: ScriptContext) -> Int {
  list.length(context.transaction.extra_signatories)
}

pub fn minted_amount(policy_id: ByteArray, token: ByteArray, context: ScriptContext) -> Int {
  value.amount_of(context.transaction.mint, policy_id, token)
}

pub fn has_reference_inputs(context: ScriptContext) -> Bool {
  list.length(context.reference_inputs) > 0
}

pub fn outputs_have_min_ada(min_ada: Int, outputs: List(TxOutput)) -> Bool {
  list.all(outputs, fn(output) { value.amount_of(output.value, #[], #[]) >= min_ada })
}

pub fn reference_inputs_within(limit: Int, context: ScriptContext) -> Bool {
  list.length(context.reference_inputs) <= limit
}
```

- `transaction.outputs`：每个 `TxOutput` 都含 `address`、`value`、`datum` 等字段，可遍历或搜索。
- `extra_signatories`：交易见证的签名者列表，常用于权限校验。
- `mint`：多资产 `Value`，用 `value.amount_of` 获取某个 `policyId + tokenName` 的铸造/销毁数量（正数=铸造，负数=销毁）。
- `reference_inputs`：引用输入列表；如果脚本不允许引用输入，可直接判空。
- `outputs_have_min_ada`：取 policyId 和 tokenName 均为空的 amount（ADA/Lovelace），判断是否达到最低门槛。
- `reference_inputs_within`：限制引用输入数量，避免脚本被夹带不允许的 reference。

---

## 2. 主函数：用 Redeemer 分流校验

`src/main.ak`
```gleam
pub fn main(_datum: Data, redeemer: Data, context: ScriptContext) -> Bool {
  when redeemer is {
    Data::Bytes(target) ->
      has_output_to(target, context.transaction.outputs)

    Data::List([Data::Bytes(policy), Data::Bytes(token), Data::Integer(expected)]) ->
      minted_amount(policy, token, context) == expected

    Data::Integer(min_ada) ->
      outputs_have_min_ada(min_ada, context.transaction.outputs)

    _ ->
      signer_count(context) > 0 && reference_inputs_within(0, context)
  }
}
```

- Redeemer 为 `Bytes` 时：只检查是否支付到目标地址。
- Redeemer 为 `[policy, token, amount]` 时：比对交易中实际的 minted 量。
- Redeemer 为 `Integer` 时：检查所有 outputs 的 ADA 是否至少达到给定值（lovelace）。
- 其他情况：要求至少 1 个签名，且不携带 reference inputs（或数量在限制内）。

> 这种“基于 Redeemer 决定校验路径”的写法，适合把多个情景收敛到同一个脚本入口。

---

## 3. 测试：构造 dummy context

`test/main.ak`
```gleam
use aiken/builtin.{Data, ByteArray}
use aiken/test
use cardano/transaction
use cardano_aiken/lesson12

fn ctx_with(outputs: List(transaction::TxOutput), signers: List(ByteArray)) -> transaction::ScriptContext {
  transaction::ScriptContext {
    purpose: transaction::ScriptPurpose::Spend(transaction::OutputReference::new(transaction::TxId(#[]), 0)),
    script_hash: #[],
    transaction: transaction::Transaction {
      outputs,
      extra_signatories: signers,
      reference_inputs: [],
      ..transaction::Transaction::default()
    }
  }
}

fn output_to(address: ByteArray) -> transaction::TxOutput {
  transaction::TxOutput { address, ..transaction::TxOutput::default() }
}

fn minted_redeemer(policy: ByteArray, token: ByteArray, amount: Int) -> Data {
  Data::List([Data::Bytes(policy), Data::Bytes(token), Data::Integer(amount)])
}
```

测试要点：
- `finds_output_by_address`：构造带目标地址的 output，Redeemer 用 Bytes 路径，期望通过。
- `minted_amount_defaults_to_zero`：默认 minted 为 0，Redeemer 声称 0 则通过；若要测试非零 minted，可在 context 的 `transaction.mint` 填入相应 Value。
- `min_ada_branch_*`：默认 output 的 ADA 为 0，要求 2_000_000 时应失败，要求 0 时通过；若要测试成功路径，可在 output 的 value 中填入足够 lovelace。
- `fallback_requires_signer_and_no_refs`：非列表/Bytes/Integer Redeemer 时，至少需要 1 个签名且引用输入为空。

运行：
```
$ cd /Users/zekai/Documents/Cardano/Cardano-Aiken/12_ScriptContextDeepDive
$ aiken check
    Compiling cardano_aiken/lesson12 0.1.0 (.)
   Collecting all tests scenarios across all modules
```

---

## 4. 练习
| 练习 | 操作 | 验证方式 |
| --- | --- | --- |
| 检查最小 ADA | 在 `TxOutput` 上使用 `value.amount_of` 取 `policyId=#[]`、`token=#[]`，比对是否 >= 2_000_000 | 新增 helper + 测试 |
| 统计引用输入数 | 限制 `reference_inputs` 不超过 N | 构造带引用输入的 context 测试 |
| 读取 inline datum | 在 output 上判断 `datum != None`，要求至少存在一个 inline datum | 新增 helper + 测试 |
| 多路径 Redeemer | 增加一条 Redeemer 分支处理“只允许多签” | 新增测试覆盖 |
| minted 资产多样性 | 检查 `transaction.mint` 中只出现特定的 policyId | 构造包含多资产的 Value 测试 |

---

## 5. Troubleshooting
| 问题 | 可能原因 | 解决方案 |
| --- | --- | --- |
| `unknown module cardano/transaction` | Aiken CLI 过旧 | 升级到最新 CLI（>=1.1） |
| `amount_of` 始终返回 0 | minted map 未包含该资产 | 构造的交易或 dummy context 中未设置对应 policy/token |
| 构建时提示没有 validator | 本讲仅演示 helper，无 validator | 忽略或在练习中自定义 validator 后再 build |

---

## 6. 延伸阅读
- [Aiken 标准库：`cardano/transaction`](https://aiken-lang.org/stdlib/cardano/transaction) — 查看 `ScriptContext`/`TxOutput` 结构。
- [Aiken 标准库：`cardano/value`](https://aiken-lang.org/stdlib/cardano/value) — 了解 minted map 与 Value 辅助函数。
- [Cardano reference inputs & inline datum 概念](https://docs.cardano.org/) — 官方文档解读。

下一讲将结合 inline datum 与 reference inputs，实战读取引用 UTxO 的状态与配置。
