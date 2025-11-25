# 06 · Unit Testing Basics

> 在 `test/` 中编写断言，利用 CLI 内置测试框架保障验证逻辑。把“写函数”与“写测试”变成习惯。

---

## 学习目标
1. 熟悉 `test` 模块结构与 `test fn` 语法。
2. 使用 `expect` 等断言 API 验证纯函数，再过渡到 validator。 
3. 掌握 `aiken check --match-tests ...` 过滤测试的方法。

## 开始前贴士
| 步骤 | 命令/动作 | 说明 |
| --- | --- | --- |
| 打开目录 | `cd /Users/zekai/Documents/Cardano/Cardano-Aiken/06_UnitTestingBasics` |
| 运行全部测试 | `aiken check`（自动编译 src/test） |
| 只运行特定测试 | `aiken check --match-tests add_numbers` | 

## 本讲文件速览
| 文件/目录 | 作用 |
| --- | --- |
| `README.md` | 本讲讲义、示例、练习与 CLI 输出。 |
| `aiken.toml` | 声明包名 `cardano_aiken/lesson06`、Plutus 版本。 |
| `src/main.ak` | 示例函数 `add`、`is_even`，可轻松编写测试。 |
| `test/main.ak` | `test fn add_numbers()`、`check_even()`，演示断言写法。 |
| `plutus.json`、`build/…` | `aiken build` 生成的产物（本讲暂无 validator，可忽略警告）。 |

---

## 1. 示例函数

```gleam
pub fn add(a: Int, b: Int) -> Int {
  a + b
}

pub fn is_even(value: Int) -> Bool {
  value % 2 == 0
}
```

---

## 2. 编写测试

```gleam
use aiken/test
use cardano_aiken/lesson06.{add, is_even}

test fn add_numbers() {
  expect 4 = add(2, 2)
}

test fn check_even() {
  expect True = is_even(4)
  expect False = is_even(5)
}
```

---

## 3. 运行命令示例
```
$ cd /Users/zekai/Documents/Cardano/Cardano-Aiken/06_UnitTestingBasics
$ aiken check
    Compiling cardano_aiken/lesson06 0.1.0 (.)
   Collecting all tests scenarios across all modules
$ aiken check --match-tests add_numbers
    Compiling cardano_aiken/lesson06 0.1.0 (.)
   Collecting test *add_numbers* across all modules
```

---

## 4. 练习
| 练习 | 操作 | 验证方式 |
| --- | --- | --- |
| 添加 `subtract` 函数 | 在 `src/main.ak` 写 `subtract` 并测试 | `aiken check` |
| 演示失败栈 | 故意写个失败断言（例如 `expect True = is_even(3)`），观察 CLI 输出 | `aiken check`（终端将显示失败信息） |
| 组合测试 | 使用 `Result` 或 `Option` 作为断言对象，练习 `expect Some(...)` | `aiken check` |

---

## 5. Troubleshooting
| 问题 | 可能原因 | 解决方案 |
| --- | --- | --- |
| `unknown module cardano_aiken/lesson06` | `aiken.toml` 的 `name` 与 `use` 路径不一致 | 保持 `name = "cardano_aiken/lesson06"`，并在测试里用同样前缀 |
| `test fn ... must return Bool` | 在测试里返回了其他类型 | 确保 `test fn` 的最后一行是 `expect` 或者直接返回 `Bool` |
| `type mismatch` | `expect` 左右类型不同 | 确认类型一致，例如 `expect Bool = Bool` |

---

## 6. 延伸阅读
- [Aiken Test 文档](https://aiken-lang.org/testing)
- [Property-based Testing 入门（Haskell QuickCheck 思路）](https://en.wikipedia.org/wiki/QuickCheck)

下一讲我们将把测试与链上脚本结合，学习如何对 validator 做单元测试。
