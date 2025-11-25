# 04 · Modules & Stdlib

> 拆分模块、复用标准库，构建可读性高的 on-chain 代码。把“utils”不再堆在一个文件里，而是会合理组织与引用。

---

## 学习目标
1. 理解 `use namespace/module`、别名、相对导入的语法。
2. 将公共函数抽到 `lib/helpers.ak`，在其他模块引用。
3. 熟悉常用标准库（List/Result/Option 等）并在项目中实践。

## 开始前贴士
| 步骤 | 命令/动作 | 说明 |
| --- | --- | --- |
| 打开目录 | `cd /Users/zekai/Documents/Cardano/Cardano-Aiken/04_ModulesAndStdlib` |
| 运行测试 | `aiken check`，输出 `Compiling ... Collecting all tests` 即代表成功 |
| 生成 `plutus.json`（可选） | `aiken build --trace-level verbose`，末尾会提示 “You do not have any validators to build!” ——因为本讲没有脚本，是正常现象 |

---

## 1. 项目结构
```
04_ModulesAndStdlib/
├── aiken.toml
├── lib/
│   └── helpers.ak        # 公共函数
├── src/main.ak           # 业务逻辑，引用 helpers
└── test/main.ak          # 针对 helpers 的断言
```

- `lib/` 目录中的模块通过 `use cardano_aiken/lesson04/helpers` 引入。
- `src/` 下可以继续拆分多个文件，例如 `metrics.ak`、`validators/*.ak`，这里用 `main.ak` 演示最简单用法。

---

## 2. 将 List API 封装成模块

`lib/helpers.ak`：
```gleam
use aiken/collection/list

pub fn average(values: List(Int)) -> Option(Int) {
  let total = list.fold(values, 0, fn(acc, v) { acc + v })
  let count = list.length(values)

  if count == 0 {
    None
  } else {
    Some(total / count)
  }
}
```

`src/main.ak` 引用：
```gleam
use cardano_aiken/lesson04/helpers

pub fn describe_avg(values: List(Int)) -> String {
  when helpers.average(values) is {
    Some(avg) -> Int.to_string(avg)
    None -> "0"
  }
}
```

---

## 3. 测试：跨模块导入

```gleam
use aiken/test
use cardano_aiken/lesson04/helpers.{average}

test fn average_positive() {
  expect Some(2) = average([1, 2, 3])
}
```

运行：
```bash
aiken check
```

---

## 4. 练习
| 练习 | 操作 | 验证方式 |
| --- | --- | --- |
| 添加 `median` 函数 | 在 `lib/helpers.ak` 里实现 `median`，排序后取中位数 | `aiken check` |
| 模块别名 | 在 `src/main.ak` 里用 `use cardano_aiken/lesson04/helpers as H`，调用 `H.average` | `aiken check` |
| 使用 Result | 将平均数改写为 `Result(Int, String)`，在 `test/` 写成功/失败断言 | `aiken check` |

---

## 5. 运行结果

```
$ cd /Users/zekai/Documents/Cardano/Cardano-Aiken/04_ModulesAndStdlib
$ aiken check
    Compiling cardano_aiken/lesson04 0.1.0 (.)
   Collecting all tests scenarios across all modules
$ aiken build --trace-level verbose
    Compiling cardano_aiken/lesson04 0.1.0 (.)
   Generating project's blueprint (./plutus.json)
  ⚠ You do not have any validators to build!
```

---

## 6. Troubleshooting
| 问题 | 可能原因 | 解决方案 |
| --- | --- | --- |
| `unknown module cardano_aiken/lesson04` | `aiken.toml` 的 `name` 与项目路径不一致 | 保持 `name = "cardano_aiken/lesson04"`，并在 `use` 语句中引用该命名空间 |
| `duplicate module helpers` | 文件名冲突 | 确保 `lib/helpers.ak` 只有一份，或不要与其他 `.ak` 同名 |
| `type mismatch` | `when` 分支返回类型不同 | 确认 `Some`、`None` 都返回 `String`（或同一类型），避免一个分支返回 `Int` 另一个返回 `String` |

---

## 7. 延伸阅读
- [Aiken stdlib 文档](https://aiken-lang.org/stdlib)
- [Gleam Module & Package 管理](https://gleam.run/book/tour/modules.html)

下一讲将继续向工程实践延伸：把项目配置、CLI 命令与文档生成串联起来。
