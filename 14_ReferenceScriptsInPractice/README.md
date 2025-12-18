# 14 · Reference Scripts In Practice

> 建立 reference script UTxO，后续交易只“引用”脚本而不再携带脚本字节，节省费用。

---

## 学习目标
1. 理解 reference script UTxO 的结构：`reference_script` 字段存放已编译脚本。
2. 掌握“两阶段”流程：先部署脚本 UTxO，再在后续交易中引用它（`--read-only-tx-in-reference`/`--spending-tx-in-reference`）。
3. 通过最小脚本与测试演示引用脚本逻辑，避免 Aiken 1.1.19 的模块解析坑。

## 开始前贴士
| 步骤 | 命令/动作 | 说明 |
| --- | --- | --- |
| 打开目录 | `cd /Users/zekai/Documents/Cardano/Cardano-Aiken/14_ReferenceScriptsInPractice` | |
| 编译 & 测试 | `aiken check` | 会运行 `test/` 里的断言，默认忽略 `.off` 的 validator（保持 `.off` 可绕过 1.1.19 解析 bug） |
| 构建 blueprint（需要 validator 时） | `mv validators/reference_script.ak.off validators/reference_script.ak` → `aiken build --trace-level verbose` | build/blueprint 完成后可再改回 `.off` 以便 `aiken check` |
| 计算地址/哈希 | `aiken blueprint address --module reference_script --validator reference_script` | 需先完成 build |

## 本讲文件速览
| 文件/目录 | 作用 |
| --- | --- |
| `README.md` | 本讲讲义、命令示例、练习与 Troubleshooting。 |
| `aiken.toml` | 声明包名 `cardano_aiken/lesson14`、Plutus 版本。 |
| `src/main.ak` | 最小可引用脚本：检查交易是否有签名者，Redeemer 可选 Bytes `"ref-ok"`。 |
| `test/main.ak` | 构造 dummy context，验证 signer 检查与 Redeemer 分支。 |
| `validators/reference_script.ak.off` | 参考用 validator；改名为 `.ak` 后可 build/导出地址，遇到 1.1.19 bug 时可保持 `.off` 运行 check。 |

---

## 1. 脚本逻辑（可被引用）

`src/main.ak`
```gleam
use aiken/builtin.{Data}
use aiken/collection/list
use cardano/transaction.{ScriptContext}

pub fn has_signer(context: ScriptContext) -> Bool {
  list.length(context.transaction.extra_signatories) > 0
}

pub fn main(_datum: Data, redeemer: Data, context: ScriptContext) -> Bool {
  when redeemer is {
    Data::Bytes(bytes) -> bytes == #"ref-ok" && has_signer(context)
    _ -> has_signer(context)
  }
}
```

- 脚本逻辑极简，适合放入 reference script UTxO，被多笔交易重复引用。
- 可以把 `has_signer` 换成业务校验（例如 owner 判断、最小支付额检查等），引用脚本仍然复用同一哈希。

`validators/reference_script.ak.off`
```gleam
use cardano_aiken/lesson14

validator reference_script {
  spend(datum, redeemer, context) {
    lesson14.main(datum, redeemer, context)
  }
}
```
- 改回 `.ak` 后即可 `aiken build`，生成 `plutus.json` 供地址/哈希计算。
- 若 `aiken check` 遇到 `unknown module ... lesson14`（1.1.19 已知问题），可保持 `.off` 运行 check，build 前再改回。

---

## 2. 测试（dummy context）

`test/main.ak`
```gleam
use aiken/builtin.{Data, ByteArray}
use aiken/test
use cardano/transaction
use cardano_aiken/lesson14

fn ctx_with_signers(signers: List(ByteArray)) -> transaction::ScriptContext {
  transaction::ScriptContext {
    purpose: transaction::ScriptPurpose::Spend(transaction::OutputReference::new(transaction::TxId(#[]), 0)),
    script_hash: #[],
    transaction: transaction::Transaction {
      extra_signatories: signers,
      ..transaction::Transaction::default()
    }
  }
}

test fn rejects_without_signer() {
  let ctx = ctx_with_signers([])
  expect False = lesson14::main(Data::Bytes(#""), Data::Bytes(#"ref-ok"), ctx)
}

test fn accepts_with_signer_and_flag() {
  let ctx = ctx_with_signers([#"sig"])
  expect True = lesson14::main(Data::Bytes(#""), Data::Bytes(#"ref-ok"), ctx)
}

test fn accepts_fallback_with_signer() {
  let ctx = ctx_with_signers([#"sig"])
  expect True = lesson14::main(Data::Bytes(#""), Data::Integer(42), ctx)
}
```

运行：
```
$ cd /Users/zekai/Documents/Cardano/Cardano-Aiken/14_ReferenceScriptsInPractice
$ aiken check
    Compiling cardano_aiken/lesson14 0.1.0 (.)
   Collecting all tests scenarios across all modules
```

---

## 3. Reference Script 两阶段流程

1) **部署脚本 UTxO（携带 reference script）**
   ```
   # 构建脚本哈希 & 地址
   mv validators/reference_script.ak.off validators/reference_script.ak
   aiken build --trace-level verbose
   aiken blueprint address --module reference_script --validator reference_script > ref.addr

   # cardano-cli 构建携带 reference script 的输出
   cardano-cli transaction build \
     --tx-in <your-utxo> \
     --tx-out "$(cat ref.addr)+2000000" \
     --tx-out-reference-script-file ./plutus.json \
     --change-address <your-change-addr> \
     --out-file create-ref.raw
   cardano-cli transaction sign --tx-body-file create-ref.raw ... --out-file create-ref.signed
   cardano-cli transaction submit --tx-file create-ref.signed ...
   ```
   > `--tx-out-reference-script-file plutus.json` 会把脚本字节放入该 UTxO 的 `reference_script` 字段。

2) **消费时引用脚本（无需再次携带脚本）**
   ```
   # 假设引用脚本 UTxO 为 TxId#Ix
   cardano-cli transaction build \
     --spending-tx-in <to-spend> \
     --spending-plutus-script-v3 \
     --spending-reference-tx-in <TxId>#<Ix> \
     --spending-reference-script-size 0 \
     --spending-plutus-script-redeemer-file redeemer.json \
     --spending-plutus-script-datum-value null \
     --tx-in-collateral <your-collateral> \
     --change-address <your-change-addr> \
     --out-file spend-ref.raw
   ```
   > 关键参数：`--spending-reference-tx-in` 指向 reference script UTxO；引用后交易里无需再携带脚本字节，费用下降。

---

## 4. 练习
| 练习 | 操作 | 验证方式 |
| --- | --- | --- |
| 加入业务校验 | 在 `has_signer` 基础上增加 owner 或最小 ADA 检查 | 修改 `main` 与测试 |
| 同时准备 Minting/Spending reference script | 在 `validators/` 增加 mint handler，生成两个 reference 脚本 UTxO | `aiken build` + cardano-cli 构建 |
| 比较费用 | 用 cardano-cli 构建“携带脚本”和“引用脚本”两笔交易，记录 fee 差异 | 命令输出对比 |
| Reference + Inline datum | 部署同时带 inline datum 的 reference UTxO，消费时读取 datum | 在 `main` 中解析 `context.reference_inputs` |

---

## 5. Troubleshooting
| 问题 | 可能原因 | 解决方案 |
| --- | --- | --- |
| `unknown module ... lesson14` | Aiken 1.1.19 已知解析 bug | `aiken check` 时保持 validator 为 `.off`；build 时改回 `.ak` |
| CLI 报 “no validators” | validator 文件仍是 `.off` | build 前改名为 `.ak` |
| 引用脚本未被用上 | `--spending-reference-tx-in` 参数缺失或指向错误 | 确认引用的 TxId#Ix 正确，且脚本版本/哈希匹配 |
| 费用未明显下降 | 交易过小或其他字段占用资源 | 比较大脚本体积时差异更显著，检查是否仍携带脚本字节 |

---

## 6. 延伸阅读
- [Aiken 标准库：`cardano/transaction`](https://aiken-lang.org/stdlib/cardano/transaction)
- [Cardano Reference Scripts 概念](https://docs.cardano.org/) — 官方说明与交易参数。
- [cardano-cli reference script 参数](https://docs.cardano.org/) — `--tx-out-reference-script-file`、`--spending-reference-tx-in` 等用法。

下一讲将继续探索更复杂的引用模式，结合 reference inputs 与 reference scripts 进一步降低成本。
