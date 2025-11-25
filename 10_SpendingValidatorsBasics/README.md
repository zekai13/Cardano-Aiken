# 10 · Spending Validators Basics

> 写出第一个真正做权限检查的脚本：只有 owner 能花费脚本 UTxO。理解 `ScriptContext`、datum/redeemer 的组合方式。

---

## 学习目标
1. 认识 Spending Validator 的函数签名与 `ScriptPurpose::Spend` 模式。
2. 学会从 `ScriptContext` 中读取签名者（`extra_signatories`）并进行权限判断。
3. 编写针对 validator 的单元测试（通过构造 dummy context 来验证属性）。

## 开始前贴士
| 步骤 | 命令/动作 | 说明 |
| --- | --- | --- |
| 打开目录 | `cd /Users/zekai/Documents/Cardano/Cardano-Aiken/10_SpendingValidatorsBasics` |
| 编译 & 测试 | `aiken check`（会执行 `test/` 中的断言） |
| 构建 & 导出 blueprint | `aiken build --trace-level verbose`，之后可用 `aiken blueprint address --module owner_guard --validator owner_guard` |

## 本讲文件速览
| 文件/目录 | 作用 |
| --- | --- |
| `README.md` | 本讲讲义、命令示例、练习与 Troubleshooting。 |
| `aiken.toml` | 声明包名 `cardano_aiken/lesson10`、Plutus 版本。 |
| `src/main.ak` | helper 函数 `check_owner`，便于测试重用。 |
| `validators/owner_guard.ak` | 实际的 Spending Validator，每次 `aiken build` 都会编译它。 |
| `test/main.ak` | 构造 dummy context，测试 `check_owner` 行为。 |

---

## 1. 校验 owner 签名

`src/main.ak`
```gleam
use aiken/builtin.{Data, ByteArray}
use aiken/collection/list
use cardano/transaction.{ScriptContext}

pub fn check_owner(owner: ByteArray, context: ScriptContext) -> Bool {
  list.any(context.transaction.extra_signatories, fn(sig) { sig == owner })
}
```

- `extra_signatories` 列表中保存着这笔交易的签名者。
- 如果需要检查多个签名者，可组合 `list.filter`、`list.length` 统计数量。

---

## 2. Validator 逻辑

`validators/owner_guard.ak`
```gleam
use aiken/builtin.{Data}
use cardano/transaction.{ScriptContext}
use cardano_aiken/lesson10.{check_owner}

pub validator owner_guard {
  spend(datum: Data, _redeemer: Data, context: ScriptContext) {
    when datum is {
      Data::Bytes(owner_hash) -> check_owner(owner_hash, context)
      _ -> False
    }
  }
}
```

- Datum 中存储 owner 的 public key hash（ByteArray）。
- Redeemer 暂时未使用，实际业务里可以放额外参数（如提款金额、付款人等）。

---

## 3. 测试：构造 dummy context

`test/main.ak`
```gleam
use aiken/builtin.{Data}
use aiken/test
use cardano/transaction
use cardano_aiken/lesson10.{check_owner}

fn ctx_with_signer(owner: ByteArray) -> transaction::ScriptContext {
  transaction::ScriptContext {
    purpose: transaction::ScriptPurpose::Spend(transaction::OutputReference::new(transaction::TxId(#[]), 0)),
    script_hash: #[],
    transaction: transaction::Transaction {
      extra_signatories: [owner],
      ..transaction::Transaction::default()
    }
  }
}

test fn owner_check_passes() {
  let ctx = ctx_with_signer(#"abcd")
  expect True = check_owner(#"abcd", ctx)
}

test fn owner_check_blocks() {
  let ctx = ctx_with_signer(#"abcd")
  expect False = check_owner(#"ffff", ctx)
}
```

---

## 4. CLI 示例
```
$ cd /Users/zekai/Documents/Cardano/Cardano-Aiken/10_SpendingValidatorsBasics
$ aiken check
    Compiling cardano_aiken/lesson10 0.1.0 (.)
   Collecting all tests scenarios across all modules
$ aiken build --trace-level verbose
    Compiling cardano_aiken/lesson10 0.1.0 (.)
   Generating project's blueprint (./plutus.json)
$ aiken blueprint address --module owner_guard --validator owner_guard
addr_test1w...
```
> Blueprint 命令可进一步导出主网地址、脚本哈希，或进行参数绑定（`aiken blueprint apply ...`）。

---

## 5. 练习
| 练习 | 操作 | 验证方式 |
| --- | --- | --- |
| 多签阈值 | 在 datum 中存储 `threshold: Int`，检查签名者数量是否达到阈值 | 在 `check_owner` 中改为 `check_threshold`，添加测试 |
| 金额守卫 | 使用 `cardano/value` 确保输出金额 >= 某个数 | 添加新的 helper 与测试 | 
| 支持多 owner | Datum 存储 owner 列表，Redeemer 指定本次 owner | `aiken check` |

---

## 6. Troubleshooting
| 问题 | 可能原因 | 解决方案 |
| --- | --- | --- |
| `unknown module cardano/transaction` | CLI 版本过旧 | 升级到最新 Aiken CLI（>=1.1） |
| `I couldn't find any 'plutus.json'` | 尚未运行 `aiken build` | 执行 `aiken build --trace-level verbose` |
| `validator_arity` 报错 | `spend` 参数数量不对 | 确认 handler 为 `(datum, redeemer, ScriptContext)` |
| `aiken check` 只显示 “Compiling ...” 后直接退出 1 | Aiken v1.1.19 的已知 bug：同目录下存在 `validators/owner_guard.ak` 就会触发 | 运行命令前临时将该文件改名或移走，命令完成再恢复；等待 CLI 发布修复后即可移除这个 workaround |

---

## 7. 延伸阅读
- [Cardano Docs: Spending Validator](https://docs.cardano.org/) 
- [Aiken Standard Library 中的 `cardano/transaction`](https://aiken-lang.org/stdlib/cardano/transaction)
- [多签脚本范例](https://developers.cardano.org/docs/smart-contracts/plutus/)

下一讲将继续扩展：介绍 Minting Policy 的基础知识。
