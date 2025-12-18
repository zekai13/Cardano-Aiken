# 11 · Minting Policies Basics

> 只允许 owner 铸造（或精确销毁）固定数量的资产。认识 `mint(redeemer, policy_id, tx)` 这一类入口签名，学会读 `transaction.mint`。

---

## 学习目标
1. 区分 Spending Validator 与 Minting Policy 的入口：Mint 处理器收到 `(Redeemer, policyId, Transaction)`。
2. 用 `value.amount_of(tx.mint, policy_id, token)` 读取某资产的铸造/销毁数量。
3. 结合 Redeemer 与交易签名者做权限控制，并用 dummy 交易测试 owner-only 策略。

## 开始前贴士
| 步骤 | 命令/动作 | 说明 |
| --- | --- | --- |
| 打开目录 | `cd /Users/zekai/Documents/Cardano/Cardano-Aiken/11_MintingPoliciesBasics` | |
| 编译 & 测试 | `aiken check` | 会运行 `test/` 里的断言；若遇到 CLI 1.1.19 的验证器 bug，可临时将 `validators/owner_only_policy.ak` 改名后再跑 |
| 构建 & 导出 blueprint | `aiken build --trace-level verbose` | 生成 `plutus.json`（需要恢复验证器文件名） |
| 计算 policyId | `aiken blueprint policy --module owner_only_policy --validator owner_only_policy` | 需先完成 build |

## 本讲文件速览
| 文件/目录 | 作用 |
| --- | --- |
| `README.md` | 本讲讲义、命令示例、练习与 Troubleshooting。 |
| `aiken.toml` | 声明包名 `cardano_aiken/lesson11`、Plutus 版本。 |
| `src/main.ak` | 纯函数：解析 Redeemer、检查签名者、读取 minted 数量。 |
| `validators/owner_only_policy.ak` | Minting Policy 入口，直接转调 `lesson11.main`。 |
| `test/main.ak` | 构造 dummy 交易，验证 owner/数量判断。 |

---

## 1. Redeemer 约定 + helper 函数

`src/main.ak`
```gleam
use aiken/builtin.{Data, ByteArray}
use aiken/collection/list
use cardano/assets.{PolicyId}
use cardano/transaction.{Transaction}
use cardano/value

pub type MintConfig {
  MintConfig {
    owner: ByteArray
    token_name: ByteArray
    amount: Int
  }
}

pub fn decode_redeemer(redeemer: Data) -> Option(MintConfig) {
  when redeemer is {
    Data::List([Data::Bytes(owner), Data::Bytes(token), Data::Integer(amount)]) ->
      Some(MintConfig { owner, token_name: token, amount })
    _ ->
      None
  }
}

pub fn signer_is_owner(owner: ByteArray, tx: Transaction) -> Bool {
  list.any(tx.extra_signatories, fn(sig) { sig == owner })
}

pub fn minted_by_policy(policy_id: PolicyId, token: ByteArray, tx: Transaction) -> Int {
  value.amount_of(tx.mint, policy_id, token)
}

pub fn validate(config: MintConfig, policy_id: PolicyId, tx: Transaction) -> Bool {
  signer_is_owner(config.owner, tx)
    && minted_by_policy(policy_id, config.token_name, tx) == config.amount
}

pub fn main(redeemer: Data, policy_id: PolicyId, tx: Transaction) -> Bool {
  when decode_redeemer(redeemer) is {
    Some(config) -> validate(config, policy_id, tx)
    None -> False
  }
}
```

- Redeemer 使用三元组：`[owner_pkh, asset_name, amount]`，转换后得到 `MintConfig`。
- Mint handler 已经把 `policy_id` 传进来，无需再从 `ScriptPurpose` 里提取；`transaction.mint` 是一个多资产 `Value`。
- `value.amount_of`：给定 policyId + token name 返回铸造（正）或销毁（负）数量，未出现的资产视为 0。

---

## 2. Policy 入口

`validators/owner_only_policy.ak`
```gleam
use cardano_aiken/lesson11

validator owner_only_policy {
  mint(redeemer, policy_id, self) {
    lesson11.main(redeemer, policy_id, self)
  }
}
```

- 类型可由 `lesson11.main` 推断；若想显式标注，可写成 `mint(redeemer: Data, policy_id: PolicyId, self: Transaction)` 并引入对应模块。
- Aiken 1.1.19 已知 bug：某些情况下 `aiken check` 会因验证器文件报 “unknown module ...”；临时把该文件改名再跑 `aiken check`，跑完再恢复给 `aiken build` 使用。

---

## 3. 测试：dummy 交易

`test/main.ak`
```gleam
use aiken/builtin.{Data, ByteArray}
use aiken/test
use cardano/assets.{PolicyId}
use cardano/transaction
use cardano_aiken/lesson11

fn mint_tx(owner: ByteArray, signed: Bool) -> transaction::Transaction {
  let signers = when signed is { True -> [owner] False -> [] }

  transaction::Transaction {
    extra_signatories: signers,
    ..transaction::Transaction::default()
  }
}

fn redeemer(owner: ByteArray, token: ByteArray, amount: Int) -> Data {
  Data::List([Data::Bytes(owner), Data::Bytes(token), Data::Integer(amount)])
}

test fn decode_redeemer_triplet() {
  let args = redeemer(#"owner", #"MyToken", 100)
  expect Some(lesson11::MintConfig { owner: #"owner", token_name: #"MyToken", amount: 100 }) =
    lesson11::decode_redeemer(args)
}

test fn allows_owner_when_amount_matches() {
  let policy_id: PolicyId = #"abcd"
  let owner = #"deadbeef"
  let tx = mint_tx(owner, True)
  expect True = lesson11::main(redeemer(owner, #"MyToken", 0), policy_id, tx)
}

test fn blocks_without_owner_signature() {
  let policy_id: PolicyId = #"abcd"
  let owner = #"deadbeef"
  let tx = mint_tx(owner, False)
  expect False = lesson11::main(redeemer(owner, #"MyToken", 0), policy_id, tx)
}

test fn blocks_wrong_amount() {
  let policy_id: PolicyId = #"abcd"
  let owner = #"deadbeef"
  let tx = mint_tx(owner, True)
  expect False = lesson11::main(redeemer(owner, #"MyToken", 50), policy_id, tx)
}
```

- 这些测试没有构造非零 minted map，意味着只有在 Redeemer 声称 amount=0 时才会通过；真实交易必须把 `tx.mint` 填成你想要的数量。
- 需要测试“实际铸造 >0”时，可把 `transaction.mint` 改成包含指定 policyId/token 的 `value`（见练习）。

---

## 4. CLI 示例
```
$ cd /Users/zekai/Documents/Cardano/Cardano-Aiken/11_MintingPoliciesBasics
$ aiken check
    Compiling cardano_aiken/lesson11 0.1.0 (.)
   Collecting all tests scenarios across all modules
$ aiken build --trace-level verbose
    Compiling cardano_aiken/lesson11 0.1.0 (.)
   Generating project's blueprint (./plutus.json)
$ aiken blueprint policy --module owner_only_policy --validator owner_only_policy
policy1...
```
> 若 `aiken check` 因验证器文件报模块解析错误，可参考 Troubleshooting 的改名 workaround，再跑上述命令。

**稳定执行顺序（含 workaround）**
```
# 1) 为绕过 1.1.19 的验证器 bug，先暂时移走 validator
mv validators/owner_only_policy.ak validators/owner_only_policy.ak.off

# 2) 类型检查 & 运行测试
aiken check

# 3) 还原 validator，再进行 build/blueprint
mv validators/owner_only_policy.ak.off validators/owner_only_policy.ak
aiken build --trace-level verbose
aiken blueprint policy --module owner_only_policy --validator owner_only_policy
```
> 如果你升级到已修复版本，可省略上述改名步骤，直接 `aiken check && aiken build`。

---

## 5. 练习
| 练习 | 操作 | 验证方式 |
| --- | --- | --- |
| 构造非零 minted map | 在测试里把 `transaction.mint` 设置为包含 `policy_id`/`token` 的 `value`，让 `amount_of` 返回指定数值 | `aiken check` |
| 支持销毁 | 允许 `amount` 为负值，拒绝正负不匹配的情况 | 添加新的测试（烧毁路径） |
| 多签阈值 | Redeemer 增加 `required_sigs`，检查 `extra_signatories` 数量 | 测试 “少于阈值 -> False” |
| 限定资产名 | 把 `token_name` 固定写入脚本（不经 Redeemer 提供） | 检查任意 Redeemer token 都被拒绝 |
| 时间锁 | 引入 `valid_range`，只在某时间段允许铸造/销毁 | 构造带 `valid_range` 的 context 测试 |

---

## 6. Troubleshooting
| 问题 | 可能原因 | 解决方案 |
| --- | --- | --- |
| `Validator script has invalid arity` | Mint handler 参数数量不对 | 使用 `(redeemer, policy_id, transaction)` |
| `value.amount_of` 总返回 0 | minted map 未包含对应 policyId/token | 确认交易里把脚本当作 minting witness，并正确填充 `tx.mint` |
| `Unknown module ...` 或 `aiken check` 退出 1 | Aiken v1.1.19 已知 bug：同目录下存在验证器文件时偶发 | 运行命令前临时将 `validators/owner_only_policy.ak` 改名或移走；完成后再恢复用于 build |
| Blueprint 没生成 | 忘记运行 `aiken build` | 执行 build 后再跑 `aiken blueprint policy ...` |

---

## 7. 延伸阅读
- [Cardano Docs: Minting Policies](https://docs.cardano.org/) — 解释 policyId、资产名称组成。
- [Aiken `cardano/value` 标准库](https://aiken-lang.org/stdlib/cardano/value) — 了解 Value 结构与辅助函数。
- [Plutus Multi-Asset 设计](https://developers.cardano.org/docs/native-tokens/) — 了解 `policyId + assetName` 的编码方式。

下一讲（第 12 讲）将深入 `ScriptContext` 全字段，读懂 inputs/outputs/mint/signers 的组合用法。
