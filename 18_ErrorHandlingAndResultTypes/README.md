# 18 · Error Handling & Result Types

> 用 `Result` 表达错误上下文，把验证拆成可组合的小函数，并在 validator 中匹配错误结果。

---

## 学习目标
1. 定义自定义错误枚举 `Error`，返回 `Result((), Error)` 来描述失败原因。
2. 使用 `result.and_then` 等组合多个校验，首个失败即返回对应错误。
3. 在 validator 中匹配 `Ok(_)`/`Error(e)`，为 blueprint/审计提供清晰错误路径。

## 开始前贴士
| 步骤 | 命令/动作 | 说明 |
| --- | --- | --- |
| 打开目录 | `cd /Users/zekai/Documents/Cardano/Cardano-Aiken/18_ErrorHandlingAndResultTypes` | |
| 编译 & 测试 | `aiken check` | 会运行 `test/` 里的断言（默认忽略 `.off` 的 validator） |
| 构建 blueprint（可选） | `mv validators/error_guard.ak.off validators/error_guard.ak && aiken build --trace-level verbose` | Aiken 1.1.19 如遇解析 bug，可 build 后再改回 `.off` 继续 check |

## 本讲文件速览
| 文件/目录 | 作用 |
| --- | --- |
| `README.md` | 本讲讲义、命令示例、练习与 Troubleshooting。 |
| `aiken.toml` | 声明包名 `cardano_aiken/lesson18`、Plutus 版本。 |
| `src/main.ak` | 定义 `Error`、校验 helper（签名/金额/时间），`validate` 组合结果。 |
| `test/main.ak` | 覆盖成功/失败路径，确保每个错误码能被触发。 |
| `validators/error_guard.ak.off` | 示例 validator，改名 `.ak` 可 build。 |

---

## 1. 错误枚举与组合

`src/main.ak`
```gleam
use aiken/result
use aiken/collection/list
use cardano/transaction.{ScriptContext}

pub type Error {
  NotOwner
  InvalidAmount
  TooEarly
}

pub fn ensure_owner(is_owner: Bool) -> Result((), Error) {
  if is_owner { Ok(()) } else { Error(NotOwner) }
}

pub fn ensure_signed_by(owner: ByteArray, context: ScriptContext) -> Result((), Error) {
  if list.any(context.transaction.extra_signatories, fn(sig) { sig == owner }) { Ok(()) } else { Error(NotOwner) }
}

pub fn ensure_positive(amount: Int) -> Result((), Error) {
  if amount > 0 { Ok(()) } else { Error(InvalidAmount) }
}

pub fn ensure_after(deadline_passed: Bool) -> Result((), Error) {
  if deadline_passed { Ok(()) } else { Error(TooEarly) }
}

pub fn validate(owner: ByteArray, amount: Int, deadline_passed: Bool, context: ScriptContext) -> Result((), Error) {
  ensure_signed_by(owner, context)
    |> result.and_then(fn(_) { ensure_positive(amount) })
    |> result.and_then(fn(_) { ensure_after(deadline_passed) })
}
```

- 每个 helper 返回 `Result`，失败时携带具体 `Error`。
- `validate` 链式组合：先 owner，再金额，再时间，谁失败就立刻返回对应错误。

`validators/error_guard.ak.off`（示例匹配错误）
```gleam
use aiken/result
use cardano_aiken/lesson18

validator error_guard {
  spend(datum, redeemer, context) {
    let owner = when datum is { Data::Bytes(bytes) -> bytes _ -> #[] }
    let amount = when redeemer is { Data::Integer(x) -> x _ -> 0 }

    match lesson18.validate(owner, amount, True, context) {
      Ok(_) -> True
      Error(_) -> False
    }
  }
}
```
- 真实场景可把 `deadline_passed` 改为基于 `context.transaction.valid_range` 的判断，并将错误映射到具体错误码/字符串。

---

## 2. 测试：确保每个错误码可触发

`test/main.ak`
```gleam
use aiken/result
use aiken/test
use cardano_aiken/lesson18

test fn owner_and_positive_and_after_passes() {
  let ctx = ctx_with_signers([#"owner"])
  expect Ok(()) = lesson18::validate(#"owner", 10, True, ctx)
}

test fn fails_when_not_owner() {
  let ctx = ctx_with_signers([#"other"])
  expect Error(lesson18::Error::NotOwner) = lesson18::validate(#"owner", 10, True, ctx)
}

test fn fails_when_amount_non_positive() {
  let ctx = ctx_with_signers([#"owner"])
  expect Error(lesson18::Error::InvalidAmount) = lesson18::validate(#"owner", 0, True, ctx)
}

test fn fails_when_too_early() {
  let ctx = ctx_with_signers([#"owner"])
  expect Error(lesson18::Error::TooEarly) = lesson18::validate(#"owner", 10, False, ctx)
}
```

运行：
```
$ cd /Users/zekai/Documents/Cardano/Cardano-Aiken/18_ErrorHandlingAndResultTypes
$ aiken check
    Compiling cardano_aiken/lesson18 0.1.0 (.)
   Collecting all tests scenarios across all modules
```

---

## 3. CLI/blueprint 建议
- 若要在 blueprint 或 off-chain 提供错误文档，可在 README/blueprint 注释列出错误码：`NotOwner`、`InvalidAmount`、`TooEarly`。
- 在 validator 中匹配 `Error(e)` 时，可用 `trace` 输出错误码（开发调试）或把错误码包装到返回布尔里。

---

## 4. 练习
| 练习 | 操作 | 验证方式 |
| --- | --- | --- |
| 错误分类 | 将 `Error` 拆为枚举嵌套（权限/余额/时间），或增加错误码字段 | 扩展 `Error`，新增测试触发 |
| 上下文检查 | 在 `validate` 中引入 `ScriptContext`，基于 signers/valid_range/minted 校验 | 新增 helper + 测试 |
| trace 调试 | 在 `Error` 分支调用 `trace` 输出错误码/消息 | 本地运行 `aiken check` 查看日志 |
| blueprint 说明 | 在 README/注释列出错误码表（含编号与描述） | 无需代码，补充文档即可 |

---

## 5. Troubleshooting
| 问题 | 可能原因 | 解决方案 |
| --- | --- | --- |
| `Error(...)` 无法匹配 | 枚举导入/命名错误 | 确认 `lesson18::Error` 路径与大小写 |
| 无法看到错误上下文 | 返回 Bool 而未匹配 Result | 在 validator 中对 `Result` 做 `match`，或使用 `trace` 辅助 |
| 构建缺少 validator | `.off` 未改名 | build 前改回 `.ak`，完成后可改回 `.off` |

---

## 6. 延伸阅读
- Aiken 标准库 `aiken/result`：`map`、`and_then`、`with_default` 等。
- 错误码设计：参考常见 API/合约错误码规范，保持可读和唯一性。

下一讲将把错误处理模式应用到完整业务逻辑，结合时间锁、权限、资产检查，输出更可审计的脚本。 
