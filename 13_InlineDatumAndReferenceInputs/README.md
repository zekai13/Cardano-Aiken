# 13 · Inline Datum & Reference Inputs

> 理解 Cardano 特有的两把利器：Inline Datum 与 Reference Input，用只读引用 UTxO 携带状态/配置，节省重复携带 datum 的费用。

---

## 学习目标
1. 区分 Hash datum 与 Inline datum 的存储/费用差异，理解 inline datum 直接嵌入输出。
2. 通过 `transaction.reference_inputs` 读取引用 UTxO，提取其中的 inline datum。
3. 在 Redeemer 中切换校验路径：检查引用输入数量、owner（单个或列表）、引用 UTxO 的最小 ADA。

## 开始前贴士
| 步骤 | 命令/动作 | 说明 |
| --- | --- | --- |
| 打开目录 | `cd /Users/zekai/Documents/Cardano/Cardano-Aiken/13_InlineDatumAndReferenceInputs` | |
| 编译 & 测试 | `aiken check` | 会运行 `test/` 里的断言；若使用 `.off` 结尾的 validator，可保持该后缀跑 check |
| 构建 blueprint（可选） | `aiken build --trace-level verbose` | 若要导出 `reference_guard`，先把 `validators/reference_guard.ak.off` 改回 `.ak` 再执行；Aiken 1.1.19 遇到解析 bug 可在 build 后再改回 `.off` |

## 本讲文件速览
| 文件/目录 | 作用 |
| --- | --- |
| `README.md` | 本讲讲义、命令示例、练习与 Troubleshooting。 |
| `aiken.toml` | 声明包名 `cardano_aiken/lesson13`、Plutus 版本。 |
| `src/main.ak` | Helper：提取引用输入中的 inline datum、owner 匹配、阈值读取、引用数量/ADA 判断；`main` 演示多条校验分支。 |
| `test/main.ak` | 构造带 inline datum 的引用输入，验证不同 Redeemer 分支。 |
| `validators/reference_guard.ak.off` | 参考用 validator（重命名为 `.ak` 后可用于 build/blueprint，若遇到 Aiken 1.1.19 的模块解析 bug，可保持 `.off` 后缀跑 check）。 |

---

## 1. Inline Datum vs Hash Datum
- **Hash datum**：输出只存 datum hash，花费时需把 datum 随交易重新携带；适合体积大、重复使用不多的场景。
- **Inline datum**：datum 字节直接放在输出里，消费时无需再携带，阅读配置/状态更方便，费用略高但省去重复附带开销。
- 读取 inline datum 时，直接从输出结构上的 `datum` 字段取 `Some(Data)` 即可。

Reference Input 允许交易带上一个“只读 UTxO”，脚本可以读取其 datum/value，但不能花掉它，常用于：
- 携带配置（owner 列表、价格表、阈值等）。
- 携带全局状态（如某个合约的最新参数），避免重复 copy datum。

---

## 2. Helper & 主逻辑

`src/main.ak`
```gleam
use aiken/builtin.{Data, ByteArray}
use aiken/collection/list
use cardano/transaction.{Input, ScriptContext}
use cardano/value

pub fn reference_inline_datums(context: ScriptContext) -> List(Data) {
  list.filter_map(context.transaction.reference_inputs, fn(input) { input.resolved.datum })
}

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

pub fn has_owner_in_reference(owner: ByteArray, context: ScriptContext) -> Bool {
  list.any(reference_inline_datums(context), fn(datum) { datum_has_owner(datum, owner) })
}

pub fn threshold_from_reference(context: ScriptContext) -> Option(Int) {
  list.first(list.filter_map(reference_inline_datums(context), fn(datum) {
    when datum is {
      Data::Integer(threshold) -> Some(threshold)
      _ -> None
    }
  }))
}

pub fn reference_count_at_least(min_refs: Int, context: ScriptContext) -> Bool {
  list.length(context.transaction.reference_inputs) >= min_refs
}

pub fn reference_min_ada_at_least(min_ada: Int, context: ScriptContext) -> Bool {
  list.all(context.transaction.reference_inputs, fn(input) {
    value.amount_of(input.resolved.value, #[], #[]) >= min_ada
  })
}

pub fn main(_datum: Data, redeemer: Data, context: ScriptContext) -> Bool {
  when redeemer is {
    Data::List([Data::Bytes(owner), Data::Integer(min_ada)]) ->
      has_owner_in_reference(owner, context) && reference_min_ada_at_least(min_ada, context)
    Data::Bytes(owner) -> has_owner_in_reference(owner, context)
    Data::Integer(min_refs) -> reference_count_at_least(min_refs, context)
    _ -> list.length(reference_inline_datums(context)) > 0
  }
}
```

- `reference_inputs`：只读引用输入列表，每个元素的 `resolved` 包含完整 `TxOutput`，可直接取 inline datum。
- `reference_inline_datums`：抽取所有引用输入中的 inline datum，方便复用。
- `main` 分支：
  - Bytes Redeemer：检查引用输入里是否存在该 owner 的 inline datum（支持单 Bytes 或列表内包含）。
 - List Redeemer `[owner, min_ada]`：要求引用输入中包含该 owner 且 ADA（lovelace）不少于给定值。
 - Integer Redeemer：要求引用输入数量达到指定值（多参考用）。
 - 其他：只要存在任意 inline datum 即通过。
> 默认 `TxOutput::default()` 的 `value` 里 ADA 为 0，若要测试/演示 ADA 足够的场景，请在引用输入的 output 上填充期望的 lovelace。

---

## 3. 测试：构造引用输入

`test/main.ak`
```gleam
use aiken/builtin.{Data, ByteArray}
use aiken/test
use cardano/transaction
use cardano_aiken/lesson13

fn output_with_datum(datum: Data) -> transaction::TxOutput {
  transaction::TxOutput { datum: Some(datum), ..transaction::TxOutput::default() }
}

fn reference_input_with_inline(datum: Data) -> transaction::Input {
  transaction::Input {
    output_reference: transaction::OutputReference::new(transaction::TxId(#[]), 0),
    resolved: output_with_datum(datum)
  }
}

fn context_with_refs(refs: List(transaction::Input)) -> transaction::ScriptContext {
  transaction::ScriptContext {
    purpose: transaction::ScriptPurpose::Spend(transaction::OutputReference::new(transaction::TxId(#[]), 0)),
    script_hash: #[],
    transaction: transaction::Transaction {
      reference_inputs: refs,
      ..transaction::Transaction::default()
    }
  }
}
```

覆盖的断言：
- `finds_owner_in_reference_inline_datum`：引用输入带 `Data::Bytes(owner)` 的 inline datum，Bytes Redeemer 应通过。
- `owner_not_found_returns_false`：找不到匹配 owner 时返回 False。
- `owner_can_be_in_list_datum`：inline datum 为列表时，依然能匹配其中的 owner。
- `threshold_extracted_from_reference`：读取第一个整数阈值。
- `requires_min_reference_count`：引用输入数量不达标则失败，达到要求则通过。
- `owner_and_min_ada_list_branch`：List Redeemer `[owner, min_ada]`，当 ADA 不足时失败，要求为 0 时通过（默认值为 0）。
- `fallback_passes_when_any_inline_exists`：其他 Redeemer 情形只要有 inline datum 即通过。

运行：
```
$ cd /Users/zekai/Documents/Cardano/Cardano-Aiken/13_InlineDatumAndReferenceInputs
$ aiken check
    Compiling cardano_aiken/lesson13 0.1.0 (.)
   Collecting all tests scenarios across all modules
```

---

## 4. 两笔交易示意（流程）
1) **创建引用 UTxO**：构建一笔交易，把配置/状态作为 inline datum 写入输出并留作 UTxO，不花费。  
2) **消费引用输入**：后续交易在 `reference_inputs` 中携带上述 UTxO，脚本读取其中 datum 判定权限/参数；引用输入不会被花费。

> inline datum 直接嵌入输出；hash datum 则需携带 datum 本体。引用输入让脚本读取但不消耗该 UTxO。

---

## 5. 练习
| 练习 | 操作 | 验证方式 |
| --- | --- | --- |
| 阈值读取 | Inline datum 写成 `Data::Integer(threshold)`，Redeemer 提供实际签名数，比较 >= | 新增 helper + 测试 |
| Owner 列表 | Inline datum 为 `Data::List(Bytes...)`，检查 Redeemer 指定的 owner 是否在列表中 | 构造列表 datum 测试 |
| 最低 ADA | 在引用输入的 `value` 上检查 ADA 是否 >= 某数 | 添加 helper + 测试（示例代码已给出，默认 Value=0，可自行填充正向用例） |
| 多 reference 组合 | 要求同时存在“配置 UTxO”和“价格表 UTxO”，可按地址或 datum 结构区分 | 构造两类引用输入测试 |
| 错误提示 | 改写返回类型为 `Result(Bool, Error)`，为缺失引用/owner 不匹配定义错误码 | 为每个分支添加测试 |

---

## 6. Troubleshooting
| 问题 | 可能原因 | 解决方案 |
| --- | --- | --- |
| `reference_inputs` 为空 | 交易未携带引用输入 | 构造交易时添加 `--read-only-tx-in`（cardano-cli）或在 off-chain 代码中指定 reference inputs |
| 找不到 inline datum | 输出存的是 hash datum 或 datum=None | 创建引用 UTxO 时确保使用 inline datum |
| CLI 报 “no validators” | 本讲未定义 validator | 可忽略，或自行添加 validator 后再 build/blueprint |
| `unknown module ... lesson13` | Aiken 1.1.19 偶发解析 bug | 跑 `aiken check` 前把 validator 改名为 `.off`，需要 build 时再改回 `.ak` |

---

## 7. 延伸阅读
- [Aiken 标准库：`cardano/transaction`](https://aiken-lang.org/stdlib/cardano/transaction) — 了解 Input/Output/ScriptContext 结构。
- [Inline datum & Reference inputs](https://docs.cardano.org/) — 官方概念与交易构建方式。
- [cardano-cli `--read-only-tx-in`](https://docs.cardano.org/) — 构建引用输入交易时的命令行示例。

下一讲将继续在引用脚本（Reference Script）场景中复用已有逻辑，进一步降低交易成本。
