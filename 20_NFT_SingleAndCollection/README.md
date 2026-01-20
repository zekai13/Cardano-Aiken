# 20 · NFT: Single & Collection

> 从单枚 NFT 到系列 NFT：限制一次性铸造、系列编号与上限，便于演示 policyId/assetName 与前端接入。

---

## 学习目标
1. 单枚 NFT：一次性铸造 1 枚，必须由 owner 签名。
2. 系列 NFT：按 prefix+index 命名，限制 index 范围与每次铸造数量。
3. 掌握 `.off` → `.ak` 改名策略，生成 blueprint/policyId 供前端使用。

## 开始前贴士
| 步骤 | 命令/动作 | 说明 |
| --- | --- | --- |
| 打开目录 | `cd /Users/zekai/Documents/Cardano/Cardano-Aiken/20_NFT_SingleAndCollection` | |
| 编译 & 测试 | `aiken check` | 会运行 `test/` 里的断言（默认忽略 `.off` 的 validators） |
| 构建 blueprint | `mv validators/single_nft.ak.off validators/single_nft.ak`（collection 同理） → `aiken build --trace-level verbose` | Aiken 1.1.19 如遇解析 bug，可 build 后再改回 `.off` 继续 check |
| 导出 policyId | `aiken blueprint policy --module single_nft --validator single_nft` / `collection_nft` | 需先完成 build |

## 本讲文件速览
| 文件/目录 | 作用 |
| --- | --- |
| `README.md` | 本讲讲义、命令示例、练习与 Troubleshooting。 |
| `aiken.toml` | 声明包名 `cardano_aiken/lesson20`、Plutus 版本。 |
| `src/main.ak` | 单枚/系列 NFT 校验：签名者、assetName、铸造数量、序号上限。 |
| `test/main.ak` | 覆盖单枚与系列的正反用例。 |
| `validators/single_nft.ak.off` | 单枚 NFT policy，改名 `.ak` 可 build。 |
| `validators/collection_nft.ak.off` | 系列 NFT policy，改名 `.ak` 可 build。 |

---

## 1. 单枚 NFT 逻辑

`src/main.ak`（单枚 Redeemer: `[owner, token]`）
```gleam
pub fn signer_is_owner(owner: ByteArray, tx: Transaction) -> Bool {
  list.any(tx.extra_signatories, fn(sig) { sig == owner })
}

pub fn minted_amount(policy_id: ByteArray, token: ByteArray, tx: Transaction) -> Int {
  value.amount_of(tx.mint, policy_id, token)
}

pub fn enforce_single(config: SingleConfig, policy_id: ByteArray, tx: Transaction) -> Bool {
  signer_is_owner(config.owner, tx)
    && minted_amount(policy_id, config.token, tx) == 1
}
```

- 只允许本次铸造恰好 1 枚，且交易中有 owner 签名。
- 若需“总供应=1”，确保之后不再使用该 policyId+token 铸造即可；或配合 off-chain 记录。

---

## 2. 系列 NFT 逻辑

`src/main.ak`（系列 Redeemer: `[owner, prefix, index, max_size]`）
```gleam
pub fn enforce_collection(config: CollectionConfig, index: Int, policy_id: ByteArray, tx: Transaction) -> Bool {
  let token = config.prefix + value.int_to_bytes(index)
  let minted = minted_amount(policy_id, token, tx)

  signer_is_owner(config.owner, tx)
    && index >= 0
    && index < config.max_size
    && minted == 1
}
```

- assetName 约定：`prefix ++ int_to_bytes(index)`（可替换为更规范的编号格式）。
- `max_size` 控制系列上限；每次只能铸造 1 枚对应编号。

---

## 3. 测试

`test/main.ak`
```gleam
test fn single_mint_allows_owner_and_one_token() { ... }
test fn single_mint_blocks_wrong_amount() { ... }
test fn collection_allows_within_max_and_one_mint() { ... }
test fn collection_blocks_over_max() { ... }
test fn collection_blocks_without_owner_signature() { ... }
```

运行：
```
$ cd /Users/zekai/Documents/Cardano/Cardano-Aiken/20_NFT_SingleAndCollection
$ aiken check
    Compiling cardano_aiken/lesson20 0.1.0 (.)
   Collecting all tests scenarios across all modules
```

---

## 4. CLI 与元数据提示
- 构建后用 `aiken blueprint policy ...` 获取 policyId，再拼接 assetName（`prefix+index`）用于前端铸造。
- CIP-25/CIP-68 元数据：本讲不展开，可参考后续章节/链接，将元数据放入交易 metadata；确保 assetName 与元数据中的 name 对应。
- 生成系列时，建议 off-chain 记录已用 index，避免重复铸造。

---

## 5. 练习
| 练习 | 操作 | 验证方式 |
| --- | --- | --- |
| 总供应=1 | 在脚本中拒绝 `minted_amount != 1`，并 off-chain 确保不再铸造 | `aiken check` |
| 自定义编号 | 将 `int_to_bytes` 改为固定宽度或十六进制编码 | 更新解析/测试 |
| 白名单 | 允许多 owner 组合或多签 | 扩展 Redeemer，增加签名检查 |
| 元数据校验 | 在 Redeemer 中携带 metadata hash，脚本中比对 | 增加解析与测试 |
| 批量铸造 | 支持一次铸造多个编号（列表），限制总量与签名 | 解析列表，累加校验 |

---

## 6. Troubleshooting
| 问题 | 可能原因 | 解决方案 |
| --- | --- | --- |
| `minted_amount` 总为 0 | 交易未将脚本作为 mint witness 或 minted map 未包含该资产 | 确认 `--mint` 参数正确，policyId/token 匹配 |
| 系列编号重复 | Off-chain 未记录已用 index | 需 off-chain 或 reference datum 记录已铸编号 |
| build 报 “no validators” | validator 仍为 `.off` | build 前改回 `.ak`，完成后可再改回 `.off` 便于 check |

---

## 7. 延伸阅读
- 第 11 讲：Minting Policies Basics。
- CIP-25 / CIP-68 元数据规范。
- 前端框架（Lucid/Mesh）如何拼接 policyId + assetName 铸造/展示。 
