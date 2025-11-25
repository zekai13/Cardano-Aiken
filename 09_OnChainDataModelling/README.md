# 09 · On-Chain Data Modelling

> 掌握如何在 Datum / Redeemer 中建模状态，规划未来升级空间。明白哪些数据放 Datum、更动态的参数放 Redeemer。

---

## 学习目标
1. 熟悉在 Datum 中存放“静态状态”、在 Redeemer 中存放“这次操作参数”的思路。
2. 设计 Datum 版本号与迁移策略，确保未来升级时兼容旧状态。
3. 利用简单的状态机（例如计数器）练习 `datum -> redeemer -> 新 datum` 的迭代模式。

## 开始前贴士
| 步骤 | 命令/动作 | 说明 |
| --- | --- | --- |
| 打开目录 | `cd /Users/zekai/Documents/Cardano/Cardano-Aiken/09_OnChainDataModelling` |
| 运行测试 | `aiken check` |
| 生成 `plutus.json`（可选） | `aiken build --trace-level verbose`（无 validator，看到警告属正常） |

## 本讲文件速览
| 文件/目录 | 作用 |
| --- | --- |
| `README.md` | 本讲讲义、练习、运行结果示例。 |
| `aiken.toml` | 声明包名 `cardano_aiken/lesson09`。 |
| `src/main.ak` | 定义 `CounterDatum`、`CounterRedeemer` 和 `apply` 函数。 |
| `test/main.ak` | `increment_counter` / `reset_counter` 测试，以确保模型行为正确。 |

---

## 1. Datum *vs* Redeemer
| 放在 Datum | 放在 Redeemer |
| --- | --- |
| 稳定的状态：计数器值、订单详细信息、权限列表 | 一次性操作参数：要执行的动作、签名者列表、输入索引 |
| 访问频率高且需要链上存储 | 更灵活、由交易发起方提供的参数 |

示例：计数器需要记住当前数值（Datum 中的 `value`），但“这次是否递增/重置”可以写在 Redeemer（`Increment` / `Reset`）。

---

## 2. 计数器模型

`src/main.ak`
```gleam
pub type CounterDatum {
  CounterDatum(version: Int, value: Int)
}

pub type CounterRedeemer {
  Increment
  Reset
}

pub fn apply(datum: CounterDatum, redeemer: CounterRedeemer) -> CounterDatum {
  when redeemer is {
    Increment -> CounterDatum(datum.version, datum.value + 1)
    Reset -> CounterDatum(datum.version + 1, 0)
  }
}
```

- `version` 可用于判断 Datum 是否过期：每次 Reset 就加一，方便脚本识别旧版 Datum。
- `value` 表示当前状态。

---

## 3. 测试覆盖状态

`test/main.ak`
```gleam
use aiken/test
use cardano_aiken/lesson09.{CounterDatum, CounterRedeemer, apply}

test fn increment_counter() {
  let datum = CounterDatum { version: 1, value: 5 }
  expect CounterDatum { version: 1, value: 6 } = apply(datum, CounterRedeemer::Increment)
}

test fn reset_counter() {
  let datum = CounterDatum { version: 1, value: 5 }
  expect CounterDatum { version: 2, value: 0 } = apply(datum, CounterRedeemer::Reset)
}
```

---

## 4. CLI 示例
```
$ cd /Users/zekai/Documents/Cardano/Cardano-Aiken/09_OnChainDataModelling
$ aiken check
    Compiling cardano_aiken/lesson09 0.1.0 (.)
   Collecting all tests scenarios across all modules
$ aiken build --trace-level verbose
    Compiling cardano_aiken/lesson09 0.1.0 (.)
   Generating project's blueprint (./plutus.json)
```
> `aiken build` 会提示“没有 validators”，因为本讲只关注数据模型。

---

## 5. 练习
| 练习 | 操作 | 验证方式 |
| --- | --- | --- |
| 订单模型 | 设计 `OrderDatum { status: OrderStatus, buyer: … }` 并写 `Redeemer::Accept/Cancel` | `aiken check` |
| 版本迁移 | 在 `apply` 中识别旧版 Datum（版本号低），尝试做迁移 | `aiken check` |
| 引用输入 | 假设某些配置放在 Reference UTxO 中，编写伪代码如何读取 | 用注释或伪函数描述即可 |

---

## 6. Troubleshooting
| 问题 | 可能原因 | 解决方案 |
| --- | --- | --- |
| `pattern never matches` | 模式顺序不正确或重复 | 检查 `when` 分支，避免 `_` 在前导致后续分支无效 |
| `type mismatch` | Datum/Redeemer 结构与测试不一致 | 确保测试使用的结构体字段与 `type` 定义一致 |
| `unknown module cardano_aiken/lesson09` | `aiken.toml` 的 `name` 与命名空间不一致 | 保持 `name = "cardano_aiken/lesson09"`，并在 `use` 语句中使用相同路径 |

---

## 7. 延伸阅读
- [Cardano Docs: Datum vs Redeemer](https://docs.cardano.org/development-guides/plutus/multiple-validators)
- [EUTxO Patterns：计数器/状态机](https://plutus.readthedocs.io/en/latest/index.html)

下一讲将进入状态脚本与 Context 的进一步实战。
