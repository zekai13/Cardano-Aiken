# 03 · Types & Pattern Matching

> 通过代数数据类型构建不可变状态，并用模式匹配组织业务逻辑。把“状态机”“多分支判断”写得清晰又安全。

---

## 学习目标
1. 熟悉 `type`、record、sum type（枚举型）的声明方式。
2. 掌握 `when ... is`、守卫、嵌套匹配等写法，替代 `if/else` + flag。
3. 将模式匹配与结果类型组合，用类型系统表达业务分支。

## 预备知识
- 已完成 01、02 讲，懂得基本语法与 CLI 使用。
- 能运行 `aiken check`、`aiken build` 并阅读终端输出。

## 开始前贴士
| 步骤 | 命令/动作 | 说明 |
| --- | --- | --- |
| 打开目录 | `cd /Users/zekai/Documents/Cardano/Cardano-Aiken/03_TypesAndPatternMatching` | 本讲是独立项目，命令都在该目录执行。 |
| 编译 + 跑测试 | `aiken check` | 验证 `src/main.ak` 与 `test/main.ak`，输出 0/若干测试都属正常。 |
| 生成 `plutus.json` | `aiken build --trace-level verbose` | 目前同样没有 validator，会出现 “You do not have any validators to build!” 警告。 |

## 本讲文件速览
| 文件/目录 | 作用 |
| --- | --- |
| `README.md` | 类型与模式匹配的讲义、练习、运行结果。 |
| `aiken.toml` | 声明包名 `cardano_aiken/lesson03`、Plutus 版本。 |
| `src/main.ak` | 定义 `OrderStatus`、`label`、`next` 等示例，演示模式匹配。 |
| `test/main.ak` | `label_states`、`next_transitions` 等断言，确保每种状态分支都被覆盖。 |
| `plutus.json`、`build/…` | `aiken build` 生成的 blueprint 与缓存，虽然本讲没 validator，但 CLI 仍会输出。 |

---

## 1. 定义类型：枚举 + Record

```gleam
pub type OrderStatus {
  Draft
  Active { buyer: String, price: Int }
  Cancelled(String)
}
```

- `Draft`、`Active {...}`、`Cancelled(...)` 是同一个类型的多种形态（Sum Type）。
- `Active { buyer, price }` 是 record 语法，字段名可读性高；`Cancelled(String)` 用 tuple 样式更紧凑。

练习：尝试新增 `Completed { tx_hash: ByteArray }`，体会不同字段组合对业务描述的影响。

---

## 2. 模式匹配组织逻辑

```gleam
pub fn label(status: OrderStatus) -> String {
  when status is {
    Draft -> "Waiting"
    Active { buyer, price } -> buyer <> " offers " <> Int.to_string(price)
    Cancelled(reason) -> "Cancelled: " <> reason
  }
}
```

- 每个分支都返回 `String`，否则编译器会提醒 `type mismatch`。
- 解构 record 时可以重命名：`Active { buyer: customer, price }`。

守卫示例：
```gleam
pub fn next(action: String, current: OrderStatus) -> OrderStatus {
  when { action, current } is {
    {"activate", Draft} -> Active { buyer: "TODO", price: 0 }
    {"cancel", _} -> Cancelled("manual")
    _ -> current
  }
}
```

---

## 3. 类型组合 & 结果类型

可以把多个类型组合成新的结构，让返回值表达语义：

```gleam
pub type TransitionResult {
  Success(OrderStatus)
  Error(String)
}

pub fn safe_next(action: String, current: OrderStatus) -> TransitionResult {
  when { action, current } is {
    {"activate", Draft} -> Success(Active { buyer: "TODO", price: 0 })
    {"cancel", _} -> Success(Cancelled("manual"))
    _ -> Error("unsupported transition")
  }
}
```

这样调用方能通过模式匹配知道操作是否失败：
```gleam
when safe_next("close", OrderStatus::Draft) is {
  Success(state) -> // ok
  Error(msg) -> // 业务提示
}
```

---

## 4. 测试示例

`test/main.ak` 已提供基本断言：
```gleam
use aiken/test
use cardano_aiken/lesson03.{label, next, OrderStatus}

test fn label_states() {
  expect "Waiting" = label(OrderStatus::Draft)
}
```

运行：
```bash
aiken check
```

---

## 5. 练习
| 练习 | 操作 | 验证方式 |
| --- | --- | --- |
| 扩展状态 | 为 `OrderStatus` 添加 `Completed { tx_hash: ByteArray }` | `aiken check`，并在 `label`/`next` 中处理新分支 |
| 引入错误类型 | 写 `TransitionResult`，让 `next` 返回 `Success/Error` | 在 `test/main.ak` 添加断言，`expect TransitionResult::Error("...")` |
| 组合模式 | 尝试 `when { status, redeemer } is { ... }` 的嵌套匹配 | `aiken check` |

---

## 6. 运行结果
| 命令 | 期望输出 |
| --- | --- |
| `aiken check` | `Compiling cardano-aiken/lesson03 ... Collecting all tests` |
| `aiken build --trace-level verbose` | `Generating project's blueprint (./plutus.json)` + `⚠ You do not have any validators to build!` |

示例：
```
$ cd /Users/zekai/Documents/Cardano/Cardano-Aiken/03_TypesAndPatternMatching
$ aiken check
    Compiling cardano-aiken/lesson03 0.1.0 (.)
   Collecting all tests scenarios across all modules
$ aiken build --trace-level verbose
    Compiling cardano-aiken/lesson03 0.1.0 (.)
   Generating project's blueprint (./plutus.json)
  ⚠ You do not have any validators to build!
```

---

## 7. Troubleshooting
| 问题 | 可能原因 | 解决方案 |
| --- | --- | --- |
| `type mismatch` | 某个 `when` 分支返回类型不同 | 确保所有分支返回同一类型，或用 `when ... is { ... -> ... }` 的默认 `_` 分支。 |
| `Unknown type OrderStatus` | 忘记 `use cardano_aiken/lesson03.{OrderStatus}` | 在 `test/main.ak` 或其他模块正确导入类型。 |
| `pattern never matches` 警告 | 模式重复或覆盖 | 检查匹配顺序，避免在 `_` 之前写更具体的分支。 |

---

## 8. 延伸阅读
- [Aiken Pattern Matching 指南（官方）](https://aiken-lang.org/)
- [Gleam/Elm 状态机写法](https://gleam.run/book/tour/pattern-matching.html)
- [函数式编程中的代数数据类型介绍](https://en.wikipedia.org/wiki/Algebraic_data_type)

下一讲将继续拓展：把类型拆到不同模块，学习 `use`/`pub` 管理代码结构。
