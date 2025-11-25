# 01 · Hello Aiken

三行代码写出第一个 validator，跑通完整工具链。从这一讲开始，Cardano-Aiken 的每一篇都聚焦链上验证脚本、EUTxO 与 Aiken CLI，而不是 Solidity 式的“合约系统”思维。

---

## 学习目标
1. 通过 `aiken new` 初始化最小示例项目，认识目录结构与 `aiken.toml`。
2. 在 `validators/hello_aiken.ak` 写出永远返回 `True` 的验证脚本，理解 Aiken validator 的基本结构。
3. 使用 `aiken check`、`aiken build`、`aiken blueprint` 跑通工具链，定位脚本哈希、地址、蓝图。

## 预备知识
- 能使用终端执行基础命令；无需提前掌握 Node/Rust。
- 对 Cardano 有最基本了解：脚本依赖 Datum/Redeemer/Context。
- 已安装 [`aiken` CLI](https://aiken-lang.org/)，`aiken --version` 能成功输出版本（下一节提供安装指引）。

---

## 启动前的安装与环境建议
1. **安装 Aiken CLI**
   ```bash
   curl -sSf https://install.aiken-lang.org | sh        # 官方脚本
   source $HOME/.aiken/bin/env                          # 将 CLI 加入当前终端 PATH
   aiken --version                                      # 看到版本号即成功
   ```
   - 如果脚本无法联网，可前往 [GitHub Releases](https://github.com/aiken-lang/aiken/releases) 下载二进制，手动放到 `~/.aiken/bin/aiken` 并 `chmod +x`。
   - 习惯 Homebrew 的用户也能运行 `brew install aiken`，但需要对 `/opt/homebrew` 有写权限。

2. **编辑器与终端**
   - 推荐使用 VS Code + 内置终端，或 macOS 自带 Terminal/iTerm。运行 Aiken 命令前记得 `cd` 到具体章节目录（例如 `01_HelloAiken`）。
   - 可安装 `tree`、`lsd` 等工具方便查看目录，但不是必需。

3. **可选工具**
   - `git`: 管理进度、提交 PR。
   - `node`/`npm`: 教程后半段会接触 blueprint + 前端集成，现在不需要。

---

## 1. 快速概览：Aiken 与 Solidity 的核心差异
| Aiken | Solidity |
| --- | --- |
| 只写 on-chain validator，off-chain 需由 TS/Rust/Python 构建交易 | on-chain/off-chain 混在一个合约里 |
| EUTxO 模型，状态保存在 Datum/UTxO | 账户 + Storage，状态驻留在合约 |
| 纯函数 + 模式匹配：`fn main(datum, redeemer, context) -> Bool` | 面向对象：状态变量、modifier、继承 |
| 自带命令行：`aiken new/check/build/test/docs/blueprint` | 依赖 Hardhat/Foundry 等第三方工具 |

理解这些差异后，本教程会围绕 EUTxO + CLI 展开，避免照搬 Solidity 的“合约状态”概念。

---

## 术语速览（0 基础也能读懂）
| 术语 | 直白解释 | 在本讲里的位置 |
| --- | --- | --- |
| **validator** | “自动审核员”。它读取交易里附带的数据，决定交易能不能通过。 | `validators/hello_aiken.ak` 中的 `validator hello_aiken`。 |
| **Datum** | 像存款凭条上写的备注，用来描述脚本持有的状态。 | 示例中用 `_datum` 占位，尚未读取内容。 |
| **Redeemer** | 用户提交的“操作指令”，告诉脚本这笔交易想做什么。 | `_redeemer` 占位。 |
| **UTxO** | 未花费输出（Unspent Transaction Output），可以想成一张只有一次使用权的支票。 | handler 的 `_utxo` 参数。 |
| **Transaction** | 一次完整付款（包含输入、输出、签名等）。脚本可以在 `_tx` 里读取签名者、金额等。 |
| **Blueprint** | 描述脚本的“说明书”，前端/后端依靠它生成交易。`aiken build` 会输出 `plutus.json`，而 `aiken blueprint address` 会基于此计算地址。 |
| **Test** | CLI 自带的断言语法。哪怕只是 `expect True`，也能确保 `aiken check` 时跑通链路。 |

只要记住：validator = 判断交易是否合规的函数；Datum/Redeemer/UTxO/Transaction 只是函数的输入，本讲用占位符 `_` 一笔带过，后续章节再深入。

---

## 2. 初始化项目
```bash
aiken new hello-aiken
cd hello-aiken
tree -L 2
```

默认目录结构：
```
hello-aiken/
├── aiken.toml          # 项目配置
├── blueprint.json      # 构建后生成，供前端/后端使用
├── plutus.json         # Plutus 脚本序列化结果
├── validators/
│   └── hello_aiken.ak  # 实际 validator
└── test/
    └── main.ak         # 单元测试
```

关键配置字段（`aiken.toml`）：
- `name`：模块命名空间（建议保持 `GitHubUser.project` 格式）。
- `version`：SemVer；blueprint 会引用它标记脚本版本。
- `plutus_version`：要编译到的 Plutus 语言版本（默认 V2）。
- `license`：MIT/Apache-2.0 等，方便 Blueprint/Docs 里展示。

> 教程执行流水线一图流：
>
> ```mermaid
> flowchart LR
>   A[aiken new] --> B[编写 validators + test]
>   B --> C[aiken check]
>   C --> D[aiken build --trace-level]
>   D --> E[aiken blueprint address]
>   E --> F[获取脚本哈希/地址]
> ```

---

## 3. 编写最小脚本
在 `validators/hello_aiken.ak` 写出第一个 spending validator：

```gleam
/// 最小化示例：无条件放行输入。
pub validator hello_aiken {
  spend(_datum, _redeemer, _utxo, _tx) {
    True
  }
}
```

拆解：
- `spend` 是“有人尝试花费脚本地址上的 UTxO”时必备的入口。哪怕暂时不用参数，也要把四个占位符写齐（把 `_` 看成“我知道有这个数据，但先忽略”）。
- `True` 表示“允许这笔交易通过”，`False`（或抛错）则阻止交易。本讲用 `True` 保证任何输入都能通过，只为跑通工具链。
- `pub` 关键字表示这个 validator 会暴露给项目外部（例如未来引用 `cardano_aiken/lesson01/validators` 时可用）。

---

## 4. 运行 CLI 命令
1. 语法检查（不生成文件）：
   ```bash
   aiken check
   ```
   输出类似：
   ```
   Compiling cardano_aiken/lesson01 0.1.0 (.)
   Collecting all tests scenarios across all modules
   ```

2. 构建脚本（生成 UPLC、plutus.json）：
   ```bash
   aiken build --trace-level verbose
   ```
   - `plutus.json`：序列化脚本，可被 `cardano-cli` 或 Lucid 直接消费。
   - `uplc/`：存放 UPLC 文本/二进制，方便以后做 gas 估算。

3. 生成 Blueprint：
   ```bash
   aiken blueprint address --module hello_aiken --validator hello_aiken
   aiken blueprint address --module hello_aiken --validator hello_aiken --mainnet
   ```
   Blueprint 命令会读取 `plutus.json`，输出 Testnet/Mainnet 脚本地址。其他子命令（`apply`、`hash`、`convert`）会在后续章节使用。

4. 可选：生成文档
   ```bash
   aiken docs
   open docs/index.html
   ```

---

## 5. 验证输出
| 文件 | 内容 | 作用 |
| --- | --- | --- |
| `plutus.json` | 脚本序列化、成本模型、脚本哈希 | 部署或交给 `cardano-cli` |
| `uplc/*.uplc` | 编译后的 UPLC 代码 | 调试、燃料估算 |
| `blueprint.json` | 脚本清单（类型签名、参数、示例） | Lucid / Mesh / Blockfrost 等读取 |

通过 `aiken blueprint address --module hello_aiken --validator hello_aiken [--mainnet]` 可以直接得到脚本地址，方便测试网付款。

---

## 6. 练习
| 练习 | 操作 | 验证方式 |
| --- | --- | --- |
| 条件返回 | 修改 spend 逻辑，让 Datum = `True` 时才返回 `True`（提示：用 `when _datum is` 做匹配） | `aiken check` 通过且 `plutus.json` 更新 |
| 生成脚本地址 | `aiken blueprint address --module hello_aiken --validator hello_aiken` | 输出 `addr_test...`（Testnet），加 `--mainnet` 可得到主网地址 |
| 第一个测试 | 在 `test/main.ak` 写 `test fn my_first_test()`，断言 `expect True` | `aiken check --match-tests my_first_test` 通过 |

---

## 7. 运行结果
| 命令 | 期望输出 |
| --- | --- |
| `aiken check` | `Compiling cardano-aiken/lesson01 ...` + `Collecting all tests` |
| `aiken build --trace-level verbose` | `Generating project's blueprint (./plutus.json)` |
| `aiken blueprint address --module hello_aiken --validator hello_aiken` | `addr_test1...` |
| `aiken check --match-tests my_first_test`（若编写） | `Collecting test *my_first_test* ...` |

实机输出示例（VS Code 终端或 macOS Terminal 中执行）：

```
$ cd /Users/zekai/Documents/Cardano/Cardano-Aiken/01_HelloAiken
$ aiken check
    Compiling cardano_aiken/lesson01 0.1.0 (.)
   Collecting all tests scenarios across all modules
$ aiken build --trace-level verbose
    Compiling cardano_aiken/lesson01 0.1.0 (.)
   Generating project's blueprint (./plutus.json)
$ aiken blueprint address --module hello_aiken --validator hello_aiken
addr_test1wqujm3k28plauhhc4l2mru3lyzde7ghpr3k089xfudhaaksy52k7q
$ aiken blueprint address --module hello_aiken --validator hello_aiken --mainnet
addr1wyujm3k28plauhhc4l2mru3lyzde7ghpr3k089xfudhaakslu7239
```

---

## 8. Troubleshooting
| 问题 | 可能原因 | 解决方案 |
| --- | --- | --- |
| `aiken: command not found` | CLI 未安装或 PATH 未配置 | 参考官方文档 `curl ... | sh` 安装，或把 `~/.aiken/bin` 加到 PATH |
| `Unknown command blueprint` | CLI 版本过旧（旧版 blueprint 命令叫 `print`） | 升级 CLI：`aiken update` 或重新安装 |
| `validator_arity` 错误 | `spend` 参数不足（必须 4 个） | 写成 `spend(_datum, _redeemer, _utxo, _tx)`，不使用的参数前面加 `_` |
| `unknown module` | `use xxx` 引用了不存在的模块 | 确认 `aiken.toml` 的 `name` 与 `use` 路径一致，或删掉没用的 import |

---

## 9. 延伸阅读
- [Aiken 官方入门文档](https://aiken-lang.org/)
- [Cardano Docs: UTxO vs Account Model](https://docs.cardano.org/)
- [WTF-Solidity 仓库](https://github.com/AmazingAng/WTF-Solidity) — 参考结构但注意 EUTxO 差异

下一讲我们将从语言层面快速走一遍语法，正式进入 Aiken 的表达式世界。
