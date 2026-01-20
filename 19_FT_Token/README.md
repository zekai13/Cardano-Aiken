# 19 · FT Token

> 通过 Minting Policy 实现教育版 FT：签名 + 供应上限，便于演示 blueprint 与前端集成。

---

## 学习目标
1. 复用第 11 讲的 Minting Policy 签名校验思路，确保只有 owner 能铸造。
2. 使用 `value.amount_of` 读取本次铸造数量，限制不超过 cap。
3. 掌握 `.off` → `.ak` 的改名策略，生成 blueprint/policyId 供前端或 Lucid 使用。

## 开始前贴士
| 步骤 | 命令/动作 | 说明 |
| --- | --- | --- |
| 打开目录 | `cd /Users/zekai/Documents/Cardano/Cardano-Aiken/19_FT_Token` | |
| 编译 & 测试 | `aiken check` | 会运行 `test/` 里的断言（默认忽略 `.off` 的 validator） |
| 构建 blueprint | `mv validators/ft_policy.ak.off validators/ft_policy.ak && aiken build --trace-level verbose` | 遇到 1.1.19 解析 bug，可 build 后再改回 `.off` 继续 check |
| 导出 policyId | `aiken blueprint policy --module ft_policy --validator ft_policy` | 需先完成 build |

## 本讲文件速览
| 文件/目录 | 作用 |
| --- | --- |
| `README.md` | 本讲讲义、命令示例、练习与 Troubleshooting。 |
| `aiken.toml` | 声明包名 `cardano_aiken/lesson19`、Plutus 版本。 |
| `src/main.ak` | FT 逻辑：解码 redeemer、检查签名者、读取 minted 数量、cap 校验。 |
| `test/main.ak` | 构造 dummy 交易，验证 owner/供应上限判断。 |
| `validators/ft_policy.ak.off` | Minting Policy 示例，改名 `.ak` 可 build/导出 policyId。 |

---

## 1. 逻辑与类型

`src/main.ak`
```gleam
use aiken/builtin.{Data, ByteArray}
use aiken/collection/list
use cardano/transaction.{Transaction}
use cardano/value

pub type FTConfig {
  FTConfig {
    owner: ByteArray
    token: ByteArray
    cap: Int
  }
}

pub fn decode_redeemer(redeemer: Data) -> Option(FTConfig) {
  when redeemer is {
    Data::List([Data::Bytes(owner), Data::Bytes(token), Data::Integer(cap)]) ->
      Some(FTConfig { owner, token, cap })
    _ -> None
  }
}

pub fn signer_is_owner(owner: ByteArray, tx: Transaction) -> Bool {
  list.any(tx.extra_signatories, fn(sig) { sig == owner })
}

pub fn minted_amount(policy_id: ByteArray, token: ByteArray, tx: Transaction) -> Int {
  value.amount_of(tx.mint, policy_id, token)
}

pub fn validate(config: FTConfig, policy_id: ByteArray, tx: Transaction) -> Bool {
  let minted = minted_amount(policy_id, config.token, tx)
  signer_is_owner(config.owner, tx) && minted > 0 && minted <= config.cap
}

pub fn main(redeemer: Data, policy_id: ByteArray, tx: Transaction) -> Bool {
  when decode_redeemer(redeemer) is {
    Some(config) -> validate(config, policy_id, tx)
    None -> False
  }
}
```

- Redeemer 采用三元组 `[owner_pkh, token_name, cap]`。
- 当前示例只限制“本次铸造量 <= cap”；如果要限制总供应，需要配合状态或 Off-chain 记录。
- 只有包含 owner 签名的交易才允许铸造。

`validators/ft_policy.ak.off`
```gleam
use cardano_aiken/lesson19

validator ft_policy {
  mint(redeemer, policy_id, self) {
    lesson19.main(redeemer, policy_id, self)
  }
}
```

---

## 2. 测试

`test/main.ak`
```gleam
use cardano/value
use cardano/transaction
use cardano_aiken/lesson19

fn tx_with_mint(policy, token, amount, signers) -> transaction::Transaction { ... }

test fn decode_redeemer_triplet() { ... }
test fn allows_owner_mint_under_cap() { ... }
test fn blocks_without_owner_signature() { ... }
test fn blocks_over_cap() { ... }
```

运行：
```
$ cd /Users/zekai/Documents/Cardano/Cardano-Aiken/19_FT_Token
$ aiken check
    Compiling cardano_aiken/lesson19 0.1.0 (.)
   Collecting all tests scenarios across all modules
```

---

## 3. CLI 与前端提示
- 构建后用 `aiken blueprint policy ...` 获取 policyId，再拼接 asset_name 即可在前端/后端使用。
- Lucid/Mesh 中的铸造参数：policyId、assetName、quantity，需要与此脚本的 redeemer 中 `token` 一致。
- 若需要 CIP-25 元数据，可参考 NFT 章节，把元数据放在交易的 metadata 区域（本讲聚焦 FT，不涉元数据）。

---

## 4. 练习
| 练习 | 操作 | 验证方式 |
| --- | --- | --- |
| 限制总供应 | 引入状态 UTxO 或 Off-chain 计数，确保累加不超过 cap | 扩展脚本/Off-chain + 测试 |
| 允许销毁 | 允许 `minted_amount < 0`，但绝对值不超过 cap | 调整 `validate` 与测试 |
| 白名单 | Redeemer 增加白名单签名者列表，至少一个在签名集合中 | 添加 helper + 测试 |
| 多资产 | 支持多个 token_name，每个有不同 cap | Redeemer 改为 Map/List，增加解析与测试 |
| 时间锁 | 结合第 16 讲的时间判断，限制铸造窗口 | 增加时间校验 helper |

---

## 5. Troubleshooting
| 问题 | 可能原因 | 解决方案 |
| --- | --- | --- |
| `minted_amount` 总为 0 | 交易未将脚本作为 mint witness 或 minted map 未包含该资产 | 确认 `--mint` 参数正确，policyId/token 匹配 |
| 没有 owner 签名 | 缺少 `--required-signer-hash` 或签名文件 | 确认交易签名者包含 owner |
| build 报 “no validators” | validator 仍为 `.off` | build 前改回 `.ak`，完成后可改回 `.off` 继续 check |

---

## 6. 延伸阅读
- 第 11 讲：Minting Policies Basics。
- Cardano Multi-Asset 设计与 policyId/assetName 说明。
- Lucid/Mesh 铸造示例（policyId + assetName + quantity）。 
