# 08 · Using Blueprint

> 把 blueprint 当作 on-chain 与 off-chain 的契约文件，贯穿部署到前端集成。了解 `aiken blueprint` 命令族后，能快速导出脚本地址、policyId，并供 Lucid/Mesh/Blockfrost 读取。

---

## 学习目标
1. 理解 blueprint（`plutus.json` + `blueprint.json`）在链上/链下之间扮演的角色。
2. 熟悉 `aiken blueprint` 相关命令：`convert`、`address`、`hash`、`apply` 等。
3. 编写一个参数化 validator，并在 blueprint 中读出参数带来的变化。

## 开始前贴士
| 步骤 | 命令/动作 | 说明 |
| --- | --- | --- |
| 打开目录 | `cd /Users/zekai/Documents/Cardano/Cardano-Aiken/08_UsingBlueprint` |
| 编译 & 生成 blueprint | `aiken check`、`aiken build --trace-level verbose` | `build/` 与 `plutus.json` 会被更新，供 blueprint 命令使用。 |
| 导出地址 | `aiken blueprint address --module owner_guard --validator owner_guard` | 默认输出 Testnet 地址，加入 `--mainnet` 可得主网地址。 |
| 生成 JSON | `aiken blueprint convert --to cardano-cli > blueprint.json` | 可将 `plutus.json` 转换成 Blueprint 规范的 JSON。 |

## 本讲文件速览
| 文件/目录 | 作用 |
| --- | --- |
| `README.md` | 本讲讲义、命令示例、练习等。 |
| `aiken.toml` | 声明包名 `cardano_aiken/lesson08`、Plutus 版本。 |
| `src/main.ak` | 参数化的 owner-only helper 函数 `owner_only`。 |
| `test/main.ak` | 构造不同签名者，验证 `owner_only` 的逻辑。 |
| `plutus.json`、`build/…` | `aiken build` 生成的脚本描述。当前 CLI 尚未导出 validator 条目，可先学习 Blueprint 概念。 |

---

## 1. 为什么需要 Blueprint？
- **`plutus.json`**：`aiken build` 输出的原始脚本数据，包含 UPLC、成本模型、脚本哈希等信息。
- **Blueprint JSON**：`aiken blueprint convert --file plutus.json` 产生，结构按照 CIP-0333（TxPipe Blueprint）规范，方便前端/后端读取多个脚本。
- **Off-chain 工具**：Lucid、Mesh、Blockfrost 等都能直接消费 Blueprint JSON，减少自己拼接 datum/redeemer 的麻烦。

---

## 2. 参数化 helper（概念示例）

`src/main.ak`
```gleam
use aiken/builtin.{Data, ByteArray}
use aiken/collection/list
use cardano/transaction.{ScriptContext}

/// 参数化的 owner-only 验证逻辑，便于 blueprint 应参。
pub fn owner_only(owner: ByteArray, context: ScriptContext) -> Bool {
  list.any(context.transaction.extra_signatories, fn(signer) { signer == owner })
}

```

- Redeemer 中携带 ByteArray（owner hash）。在 blueprint 里可以提前固定，也可在前端按需传参。

---

`validators/owner_guard.ak`
```gleam
use aiken/builtin.{Data}
use cardano/transaction.{ScriptContext}
use cardano_aiken/lesson08.{owner_only}

/// 真正可部署的 validator。
validator owner_guard {
  spend(_datum: Data, redeemer: Data, context: ScriptContext) {
    when redeemer is {
      Data::Bytes(owner_hash) -> owner_only(owner_hash, context)
      _ -> False
    }
  }
}
```

---

## 3. 测试：确保 helper 函数生效

`test/main.ak`
```gleam
use aiken/builtin.{Data}
use aiken/test
use cardano/transaction
use cardano_aiken/lesson08.{owner_only}

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

test fn owner_only_passes() {
  let ctx = ctx_with_signer(#"abcd")
  expect True = owner_only(#"abcd", ctx)
}

test fn owner_only_blocks() {
  let ctx = ctx_with_signer(#"abcd")
  expect False = owner_only(#"ffff", ctx)
}
```

---

## 4. Blueprint 命令速查
| 命令 | 作用 | 示例输出 |
| --- | --- | --- |
| `aiken blueprint convert --file plutus.json --to cardano-cli > blueprint.json` | 将 `plutus.json` 转为 Blueprint 规范 | 输出 JSON，包含每个 validator 的 hash、参数等 |
| `aiken blueprint address --module owner_guard --validator owner_guard [--mainnet]` | 计算脚本地址 | `addr_test1...` 或 `addr1...` |
| `aiken blueprint hash --module owner_guard --validator owner_guard` | 输出脚本哈希 | `script_hash: 0x...` |
| `aiken blueprint apply --module owner_guard --validator owner_guard --args '["#abcd"]'` | 将参数（如 owner hash）连接到 blueprint | 命令会输出新的 Script JSON，可直接 `--out` 保存 |

---

## 5. 终端示例
```
$ cd /Users/zekai/Documents/Cardano/Cardano-Aiken/08_UsingBlueprint
$ aiken check
    Compiling cardano_aiken/lesson08 0.1.0 (.)
   Collecting all tests scenarios across all modules
$ aiken build --trace-level verbose
    Compiling cardano_aiken/lesson08 0.1.0 (.)
   Generating project's blueprint (./plutus.json)
(Blueprint 命令将等官方 CLI 正式支持后再演示)
```
> 注意：本讲的 hash/address 输出为示例，请以你本地生成的值为准。

---

## 6. 练习
| 练习 | 操作 | 验证方式 |
| --- | --- | --- |
| 阅读官方 Blueprint JSON 示例 | 参考 TxPipe/Sundae Labs 提供的 blueprint JSON，理解字段含义 | 手动打开 JSON |
| Lucid Demo（概念） | 在 Lucid 中 `importBlueprint("./blueprint.json")`，了解如何消费 | 概念演练，暂不运行 |
| 参数化思考 | 设计需要多个参数的 Redeemer 结构，提前构想 JSON 格式 | 在 README 或注释中写出想法 |

---

## 7. Troubleshooting
| 问题 | 可能原因 | 解决方案 |
| --- | --- | --- |
| `I couldn't find any 'plutus.json'` | 尚未运行 `aiken build` | 先执行 `aiken build --trace-level verbose` 生成 `plutus.json` |
| `unknown blueprint command` | CLI 版本偏旧 | 升级到最新 Aiken CLI（>= 1.1） |
| `invalid args` | `--args` 参数格式不对 | 使用 JSON 字符串，如 `'["#abcd"]'` 或 `'[{"owner": "#abcd"}]'` |

---

## 8. 延伸阅读
- [TxPipe Blueprint 规范](https://github.com/txpipe/blueprint)
- [Lucid 文档：从 Blueprint 加载脚本](https://github.com/spacebudz/lucid)
- [Mesh CLI / Blockfrost Blueprint 示例](https://meshjs.dev/)

下一讲将结合 blueprint 与前端 SDK，完成一次端到端的部署体验。
