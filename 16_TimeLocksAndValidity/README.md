# 16 · Time Locks & Validity

> 使用 `valid_range`、slot/time 工具编写时间锁脚本：过了某个时间才能花费，或要求交易时间落在某个区间内。

---

## 学习目标
1. 读取 `context.transaction.valid_range`，用 `time.contains_from` / `time.contains` 做时间窗口判断。
2. 用 Redeemer 传入解锁时间或时间区间，组合“解锁/退款”路径。
3. 了解 CLI 构建时如何设置 `--invalid-before/--invalid-hereafter`（slot 或 POSIX）。

## 开始前贴士
| 步骤 | 命令/动作 | 说明 |
| --- | --- | --- |
| 打开目录 | `cd /Users/zekai/Documents/Cardano/Cardano-Aiken/16_TimeLocksAndValidity` | |
| 编译 & 测试 | `aiken check` | 会运行 `test/` 里的断言（默认忽略 `.off` 的 validator） |
| 构建 blueprint（可选） | `mv validators/time_lock.ak.off validators/time_lock.ak && aiken build --trace-level verbose` | Aiken 1.1.19 如遇解析 bug，可 build 后再改回 `.off` 继续 check |
| 设置交易时间 | `cardano-cli ... --invalid-before <slot> --invalid-hereafter <slot>` | 控制 valid_range；POSIX 需按网络参数换算为 slot |

## 本讲文件速览
| 文件/目录 | 作用 |
| --- | --- |
| `README.md` | 本讲讲义、命令示例、练习与 Troubleshooting。 |
| `aiken.toml` | 声明包名 `cardano_aiken/lesson16`、Plutus 版本。 |
| `src/main.ak` | Helper：`after` / `between` 检查 valid_range；`main` 根据 Redeemer 选择路径。 |
| `test/main.ak` | 构造 dummy valid_range，覆盖 after/between 的正反用例。 |
| `validators/time_lock.ak.off` | 参考 validator，改名为 `.ak` 可 build/导出 blueprint。 |

---

## 1. Time helper 函数

`src/main.ak`
```gleam
use aiken/builtin.{Data, Int}
use cardano/time
use cardano/transaction.{ScriptContext}

pub fn after(deadline: Int, context: ScriptContext) -> Bool {
  time.contains_from(context.transaction.valid_range, deadline)
}

pub fn between(start: Int, end: Int, context: ScriptContext) -> Bool {
  time.contains(context.transaction.valid_range, time.from_slots(start, end))
}

pub fn main(_datum: Data, redeemer: Data, context: ScriptContext) -> Bool {
  when redeemer is {
    Data::Integer(deadline) -> after(deadline, context)
    Data::List([Data::Integer(start), Data::Integer(end)]) -> between(start, end, context)
    _ -> False
  }
}
```

- `after(deadline)`: 交易的 valid_range 必须从该 slot（含）开始或更晚。
- `between(start, end)`: valid_range 必须完全落在 `[start, end]` 内；使用 `time.from_slots` 构造区间。
- 可将 `deadline/start/end` 换成 POSIX 时间，只要构造的区间与交易一致。

`validators/time_lock.ak.off`
```gleam
use cardano_aiken/lesson16

validator time_lock {
  spend(datum, redeemer, context) {
    lesson16.main(datum, redeemer, context)
  }
}
```
- 改名为 `.ak` 后可 build/导出地址；遇到解析 bug 可再改回 `.off` 继续 `aiken check`。

---

## 2. 测试：构造 valid_range

`test/main.ak`
```gleam
use aiken/builtin.{Data}
use aiken/test
use cardano/time
use cardano/transaction
use cardano_aiken/lesson16

fn ctx_with_range(start: Int, end: Int) -> transaction::ScriptContext {
  transaction::ScriptContext {
    purpose: transaction::ScriptPurpose::Spend(transaction::OutputReference::new(transaction::TxId(#[]), 0)),
    script_hash: #[],
    transaction: transaction::Transaction {
      valid_range: time.from_slots(start, end),
      ..transaction::Transaction::default()
    }
  }
}

test fn after_passes_when_range_starts_at_deadline() {
  let ctx = ctx_with_range(100, 200)
  expect True = lesson16::main(Data::Constr(0, []), Data::Integer(100), ctx)
}

test fn after_fails_when_before_deadline() {
  let ctx = ctx_with_range(50, 99)
  expect False = lesson16::main(Data::Constr(0, []), Data::Integer(100), ctx)
}

test fn between_passes_inside_range() {
  let ctx = ctx_with_range(100, 200)
  expect True = lesson16::main(Data::Constr(0, []), Data::List([Data::Integer(120), Data::Integer(180)]), ctx)
}

test fn between_fails_when_outside_range() {
  let ctx = ctx_with_range(100, 150)
  expect False = lesson16::main(Data::Constr(0, []), Data::List([Data::Integer(120), Data::Integer(180)]), ctx)
}
```

运行：
```
$ cd /Users/zekai/Documents/Cardano/Cardano-Aiken/16_TimeLocksAndValidity
$ aiken check
    Compiling cardano_aiken/lesson16 0.1.0 (.)
   Collecting all tests scenarios across all modules
```

---

## 3. CLI: 设置 valid_range

示例：只允许在 slot 1_000_000 之后消费，且不晚于 1_100_000。
```
cardano-cli transaction build \
  ... \
  --invalid-before 1000000 \
  --invalid-hereafter 1100000 \
  --out-file tx.raw
```
- `--invalid-before` 对应 valid_range 下界（含）；`--invalid-hereafter` 对应上界（不含）。
- 使用 POSIX 时间时需先换算为 slot；主网与测试网的 slot 长度不同，请参考网络参数。

---

## 4. 练习
| 练习 | 操作 | 验证方式 |
| --- | --- | --- |
| 解锁 + 退款 | Redeemer 区分“解锁/退款”两条路径，退款要求过期时间后才允许 | 添加 Redeemer 分支与测试 |
| POSIX 时间 | 使用 `time.from_posix` 构造区间，测试 POSIX 与 slot 两种输入 | 增加 helper 与测试 |
| 角色 + 时间 | 限制特定签名者在解锁窗口内才可关闭 | 结合 extra_signatories 检查 |
| 多阶段 | 设计锁仓→释放→过期三阶段，Redeemer 控制当前阶段 | 扩展枚举与 valid_range 判定 |

---

## 5. Troubleshooting
| 问题 | 可能原因 | 解决方案 |
| --- | --- | --- |
| `time.contains_from/contains` 判定异常 | 传入的 slot/区间不符合网络参数 | 确认 slot 换算正确，或直接用同一单位（slot/posix）比较 |
| `unknown module cardano/time` | Aiken CLI 过旧 | 升级到最新 Aiken CLI（>=1.1） |
| build 报 “no validators” | validator 仍为 `.off` | build 前改回 `.ak`，完成后可改回 `.off` 便于 check |

---

## 6. 延伸阅读
- [Aiken 标准库：`cardano/time`](https://aiken-lang.org/stdlib/cardano/time) — 区间与 slot/POSIX 工具。
- [Cardano valid_range 说明](https://docs.cardano.org/) — 交易时间窗口参数。

下一讲将把时间锁与状态机/权限结合，构建更贴近实际业务的流程控制。 
