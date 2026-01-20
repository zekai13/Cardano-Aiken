# 17 · Multi Script Projects

> 在单个仓库维护多种脚本（Spending/Minting/Governance），规划目录与 blueprint 导出流程，避免混乱。

---

## 学习目标
1. 设计多脚本目录与命名：`validators/*.ak`、`scripts/` 下的共享逻辑。
2. 路由模式：统一入口 `route(kind, ...)` 分发到不同 handler。
3. 在 blueprint 中生成多个脚本条目，导出地址/PolicyId 并保持 .off 改名策略应对 1.1.19 bug。

## 开始前贴士
| 步骤 | 命令/动作 | 说明 |
| --- | --- | --- |
| 打开目录 | `cd /Users/zekai/Documents/Cardano/Cardano-Aiken/17_MultiScriptProjects` | |
| 编译 & 测试 | `aiken check` | 会运行 `test/` 里的断言（默认忽略 `.off` 的 validators） |
| 构建 blueprint | 将 `validators/*.ak.off` 改名为 `.ak`，如：`mv validators/spend_guard.ak.off validators/spend_guard.ak`；然后 `aiken build --trace-level verbose` | build 后可改回 `.off` 继续 `aiken check` |
| 导出地址/PolicyId | `aiken blueprint address --module spend_guard --validator spend_guard` / `aiken blueprint policy --module mint_guard --validator mint_guard` | 需先完成 build |

## 本讲文件速览
| 文件/目录 | 作用 |
| --- | --- |
| `README.md` | 本讲讲义、命令示例、练习与 Troubleshooting。 |
| `aiken.toml` | 声明包名 `cardano_aiken/lesson17`、Plutus 版本。 |
| `src/main.ak` | 多脚本 handler：spend/mint/governance + `route` 分发。 |
| `test/main.ak` | 触达不同 handler 的单元测试。 |
| `validators/spend_guard.ak.off` | Spending validator 示例（改名 `.ak` 可 build）。 |
| `validators/mint_guard.ak.off` | Minting validator 示例（改名 `.ak` 可 build）。 |

---

## 1. Handler 与路由

`src/main.ak`
```gleam
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
```

- Spend：简单 owner=redeemer 签名匹配。
- Mint：比对 `mint` 中指定资产数量。
- Governance：至少 2 个签名者且 redeemer=Bytes("vote")。
- `route` 提供统一入口，validator 调用时传入对应 `ScriptKind`。

`validators/spend_guard.ak.off`
```gleam
use cardano_aiken/lesson17

validator spend_guard {
  spend(datum, redeemer, context) {
    lesson17.route(lesson17::ScriptKind::Spending, datum, redeemer, context)
  }
}
```

`validators/mint_guard.ak.off`
```gleam
use cardano_aiken/lesson17

validator mint_guard {
  mint(redeemer, context) {
    lesson17.route(lesson17::ScriptKind::Minting, Data::Constr(0, []), redeemer, context)
  }
}
```

> 若需 Governance 入口，可新增 validator 并传入 `ScriptKind::Governance`。

---

## 2. 测试：确保 handler 行为正确

`test/main.ak`
```gleam
use aiken/builtin.{Data, ByteArray}
use aiken/test
use cardano/transaction
use cardano/value
use cardano_aiken/lesson17

fn ctx_with(signers: List(ByteArray), mint: value::Value) -> transaction::ScriptContext { ... }

test fn spend_handler_requires_matching_owner() { ... }
test fn mint_handler_checks_amount_of() { ... }
test fn governance_requires_two_signers_and_vote() { ... }
test fn route_dispatches_to_handlers() { ... }
```
- 覆盖 spend/mint/governance 的正反用例，并验证 `route` 分发。
- 如需更多脚本，按同样模式扩展 handler + 测试。

运行：
```
$ cd /Users/zekai/Documents/Cardano/Cardano-Aiken/17_MultiScriptProjects
$ aiken check
    Compiling cardano_aiken/lesson17 0.1.0 (.)
   Collecting all tests scenarios across all modules
```

---

## 3. 目录/blueprint 规划建议
- `src/`：放共用逻辑与 handler。
- `validators/`：每个脚本一个文件，命名与 `route` 中的 kind 对应。需要时改名 `.off` ↔ `.ak` 切换 check/build。
- `scripts/`：可放更复杂的入口或参数化脚本（例如引用 shared modules）。
- 构建时，`aiken build` 会把当前 `.ak` 的 validators 输出到 `plutus.json`，便于一次性导出多条地址/PolicyId。

---

## 4. 练习
| 练习 | 操作 | 验证方式 |
| --- | --- | --- |
| 添加 Governance validator | 创建 `validators/gov_guard.ak` 调用 `ScriptKind::Governance`，导出地址 | `aiken build` + `aiken blueprint address --module gov_guard --validator gov_guard` |
| 共享库模块 | 把 owner 校验、mint 校验抽成 `src/lib.ak`，供多个 handler 复用 | `aiken check` |
| 参数化脚本 | 在 `route` 前添加参数（如固定 owner/token），并用 `aiken blueprint apply` 生成实例 | `aiken blueprint apply ...` |
| 扩展治理逻辑 | 增加签名阈值或代币投票权重 | 新增 handler 与测试 |
| 费用对比 | 同项目内比较多个脚本的 size/fee，对目录拆分进行优化 | `aiken build` 输出的 stats 或 cardano-cli 估算 |

---

## 5. Troubleshooting
| 问题 | 可能原因 | 解决方案 |
| --- | --- | --- |
| 构建时只有部分脚本输出 | 有些 validator 仍是 `.off` 或未引用正确入口 | build 前确认要导出的 `.ak` 已改名，handler 名称匹配 |
| `unknown module ... lesson17` | Aiken 1.1.19 偶发解析 bug | `aiken check` 时保持 `.off`，build 前改回 `.ak` |
| mint 校验总为 0 | `transaction.mint` 未包含对应资产 | 构造交易/测试时正确填入 policyId/token |

---

## 6. 延伸阅读
- Aiken 文档：`aiken blueprint` 多脚本用法。
- Cardano 多脚本项目经验（参考 Plutus Pioneer Program、社区示例）。
- 结合 Lucid/Mesh 时的多脚本加载与签名策略。

下一讲将把多脚本与状态机/时间锁结合，构建更完整的 DApp 模块化结构。
