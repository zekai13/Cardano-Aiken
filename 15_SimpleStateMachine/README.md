# 15 · Simple State Machine

> 用枚举 Datum + Redeemer 构建 3 状态状态机：Init → Active → Closed，拒绝非法跳转。

---

## 学习目标
1. 定义状态枚举 Datum（`Init | Active | Closed`）与动作 Redeemer（`Start | Close | Cancel | ForceClose`）。
2. 编写 `transition/allow_transition`，仅允许合法路径：Init→Active、Active→Closed/Cancel/ForceClose。
3. 在 validator 中把 Datum/Redeemer 解码为构造子索引，验证状态机步进。

## 开始前贴士
| 步骤 | 命令/动作 | 说明 |
| --- | --- | --- |
| 打开目录 | `cd /Users/zekai/Documents/Cardano/Cardano-Aiken/15_SimpleStateMachine` | |
| 编译 & 测试 | `aiken check` | 会运行 `test/` 里的断言（默认忽略 `.off` 的 validator） |
| 构建 blueprint（可选） | `mv validators/state_machine.ak.off validators/state_machine.ak && aiken build --trace-level verbose` | Aiken 1.1.19 如遇解析 bug，可 build 后再改回 `.off` 继续 check |

## 本讲文件速览
| 文件/目录 | 作用 |
| --- | --- |
| `README.md` | 本讲讲义、命令示例、练习与 Troubleshooting。 |
| `aiken.toml` | 声明包名 `cardano_aiken/lesson15`、Plutus 版本。 |
| `src/main.ak` | 定义 State/Action 枚举（含 ForceClose）、`transition`、`allow_transition`，并在 `main` 中验证合法迁移。 |
| `test/main.ak` | 针对 `transition`/validator 的正反用例。 |
| `validators/state_machine.ak.off` | 参考 validator，改名为 `.ak` 可 build/导出 blueprint。 |

---

## 1. 状态与动作枚举

`src/main.ak`
```gleam
use aiken/builtin.{Data}

pub type State {
  Init
  Active
  Closed
}

pub type Action {
  Start
  Close
  Cancel
}

pub fn transition(state: State, action: Action) -> State {
  when { state, action } is {
    {Init, Start} -> Active
    {Active, Close} -> Closed
    {Active, Cancel} -> Closed
    _ -> state
  }
}

pub fn allow_transition(from: State, action: Action, to: State) -> Bool {
  transition(from, action) == to
}
```

- 任何非法组合都会返回原状态（保持不变），可用 `allow_transition` 判定是否为期望的新状态。

---

## 2. Validator：解码 Datum/Redeemer

`src/main.ak`
```gleam
pub fn main(datum: Data, redeemer: Data, _context: Data) -> Bool {
  when { datum, redeemer } is {
    {Data::Constr(0, []), Data::Constr(0, [])} -> allow_transition(Init, Start, Active)
    {Data::Constr(1, []), Data::Constr(1, [])} -> allow_transition(Active, Close, Closed)
    {Data::Constr(1, []), Data::Constr(2, [])} -> allow_transition(Active, Cancel, Closed)
    _ -> False
  }
}
```

- 约定编码：`State` 的 Constr 索引 `Init=0, Active=1, Closed=2`；`Action` 的 Constr 索引 `Start=0, Close=1, Cancel=2`。
- Datum/Redeemer 要与上面的枚举保持一致，否则判定为非法。

---

## 3. 测试：覆盖合法/非法路径

`test/main.ak`
```gleam
use aiken/builtin.{Data}
use aiken/test
use cardano_aiken/lesson15

fn datum_of(state: lesson15::State) -> Data { ... }
fn redeemer_of(action: lesson15::Action) -> Data { ... }

test fn start_moves_to_active() {
  expect lesson15::State::Active = lesson15::transition(lesson15::State::Init, lesson15::Action::Start)
}

test fn force_close_moves_to_closed() {
  expect lesson15::State::Closed = lesson15::transition(lesson15::State::Active, lesson15::Action::ForceClose)
}

test fn validator_blocks_invalid_action() {
  let datum = datum_of(lesson15::State::Init)
  let redeemer = redeemer_of(lesson15::Action::Close)
  expect False = lesson15::main(datum, redeemer, Data::Constr(0, []))
}

test fn validator_allows_force_close_from_active() {
  let datum = datum_of(lesson15::State::Active)
  let redeemer = redeemer_of(lesson15::Action::ForceClose)
  expect True = lesson15::main(datum, redeemer, Data::Constr(0, []))
}
```
- 还包含 Close/Cancel/ForceClose 合法路径、Init→Closed 非法路径等用例。
- 需要 Context 时可扩展第三个参数（当前示例未使用）。

运行：
```
$ cd /Users/zekai/Documents/Cardano/Cardano-Aiken/15_SimpleStateMachine
$ aiken check
    Compiling cardano_aiken/lesson15 0.1.0 (.)
   Collecting all tests scenarios across all modules
```

---

## 4. 练习
| 练习 | 操作 | 验证方式 |
| --- | --- | --- |
| 时间锁 | 给 `Close` 增加 `valid_range` 下界，过期才允许关闭 | 构造带时间的 context 测试 |
| 角色权限 | 引入 owner/admin，限制谁能 `Start/Close/Cancel` | 增加签名者检查并扩展测试 |
| 新状态 | 增加 `Paused`，允许 `Active→Paused→Active` 但禁止 `Paused→Closed` | 扩展枚举、transition 与用例 |
| 版本控制 | 为 Datum 增加 `version`，拒绝旧版本迁移 | 调整 Datum 结构与判定 |
| Blueprint 注释 | 在 README 中画出状态转移图，并在 blueprint 参数说明中标注 Datum/Redeemer 编码 | 更新文档/测试 |

---

## 5. Troubleshooting
| 问题 | 可能原因 | 解决方案 |
| --- | --- | --- |
| 状态编码错位 | Datum/Redeemer 的 Constr 索引与枚举不一致 | 确认 Constr 索引顺序与代码一致 |
| 非法跳转未被拒绝 | `transition`/`allow_transition` 判定缺少分支 | 补全匹配，增加测试覆盖 |
| 构建缺少 validator | 本讲未提供默认 validator 文件 | 若需 blueprint，新增 validators 文件并引用 `lesson15.main` |

---

## 6. 延伸阅读
- 状态机设计思路可参考 Cardano 官方文档或 Plutus Pioneer Program 的状态机章节。
- Aiken 标准库文档：`cardano/transaction`、`cardano/value` 等，用于扩展时间锁、资产检查。

下一讲将继续把状态与时间/引用输入结合，构建更复杂的状态机模式。
