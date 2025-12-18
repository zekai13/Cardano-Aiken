# 01 · Hello Aiken

三行代码写出第一个 validator，跑通完整工具链。从这一讲开始，Cardano-Aiken 的每一篇都聚焦链上验证脚本、EUTxO 与 Aiken CLI，而不是 Solidity 式的“合约系统”思维。

---

## 学习目标
1. 通过 `aiken new` 初始化最小示例项目，认识目录结构与 `aiken.toml`。
2. 在 `src/main.ak` 写出永远返回 `True` 的验证脚本，理解 `fn main(datum, redeemer, context)` 签名。
3. 使用 `aiken check`、`aiken build`、`aiken blueprint` 跑通工具链，定位脚本哈希、地址、蓝图。

## 预备知识
- 能使用终端执行基础命令；无需提前掌握 Node/Rust。
- 对 Cardano 有最基本了解：脚本依赖 Datum/Redeemer/Context。
- 已安装 [`aiken` CLI](https://aiken-lang.org/)，`aiken --version` 能成功输出版本。

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
├── src/
│   └── main.ak         # 默认 validator
└── test/
    └── main.ak         # 单元测试（可删除或扩展）
```

关键配置字段（`aiken.toml`）：
- `name`：模块命名空间（建议保持 `GitHubUser.project` 格式）。
- `version`：SemVer；blueprint 会引用它标记脚本版本。
- `plutus_version`：要编译到的 Plutus 语言版本（默认 V2）。
- `license`：MIT/Apache-2.0 等，方便 Blueprint/Docs 里展示。

---

## 3. 编写最小脚本
编辑 `src/main.ak`：

```gleam
use aiken/builtin.{Data}

/// 最小示例：永远返回 True，帮助熟悉 CLI 流程。
pub fn main(_datum: Data, _redeemer: Data, _context: Data) -> Bool {
  True
}
```

拆解：
- 参数类型都为 `Data`，因为 Datum/Redeemer/Context 在链上都是 Plutus Data。
- `_` 前缀代表暂时未使用，避免编译器警告。
- 返回值必须是 `Bool`。`True` = 交易通过；`False` => 交易失败。

---

## 4. 运行 CLI 命令
1. 语法检查（不生成文件）：
   ```bash
   aiken check
   ```
   输出类似：
   ```
   Checking hello-aiken
   ✔ Compiled src/main.ak
   ```

2. 构建脚本（生成 UPLC、plutus.json）：
   ```bash
   aiken build --trace
   ```
   - `plutus.json`：序列化脚本，可被 `cardano-cli` 或 Lucid 直接消费。
   - `uplc/`：存放 UPLC 文本/二进制。

3. 生成 Blueprint：
   ```bash
   aiken blueprint convert --file plutus.json
   aiken blueprint print
   ```
   Blueprint 是 off-chain 与 on-chain 的“契约”，描述脚本哈希、参数、样例 datum/redeemer。

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

通过 `aiken blueprint print --address <network>` 可以直接得到脚本地址，方便测试网付款。

---

## 6. 课后挑战
1. **条件返回**：修改 `src/main.ak`，当 Datum 中包含 `True` 时才放行。
2. **生成脚本地址**：运行
   ```bash
   aiken blueprint print --address --network preprod
   ```
   把输出贴到 README 的运行结果小节。
3. **写第一个测试**（可选）：
   - 在 `test/main.ak` 中引入 `src/main.ak` 的函数。
   - 使用 `test fn` + `expect True` 写最简单断言。

---

## 运行结果（示例）
```
$ aiken check
Checking hello-aiken
✔ Compiled src/main.ak

$ aiken build --trace
Writing plutus script to plutus.json
Blueprint updated at blueprint.json

$ aiken blueprint print --address --network preprod
addr_test1wxyz...90
```

---

## Troubleshooting
| 问题 | 可能原因 | 解决方案 |
| --- | --- | --- |
| `aiken: command not found` | CLI 未安装或 PATH 未配置 | 参考官方文档 `curl ... | sh` 安装，或用 `cargo install aiken` |
| `Unknown command blueprint` | CLI 版本过旧 | 升级 CLI：`aiken update` 或重新安装 |
| `aiken build` 失败，提示类型不匹配 | `main` 返回值不是 Bool / 参数类型不符 | 确认函数签名 `fn main(Data, Data, Data) -> Bool` |

---

## 延伸阅读
- [Aiken 官方入门文档](https://aiken-lang.org/)
- [Cardano Docs: UTxO vs Account Model](https://docs.cardano.org/)
- [WTF-Solidity 仓库](https://github.com/AmazingAng/WTF-Solidity) — 参考结构但注意 EUTxO 差异

下一讲我们将从语言层面快速走一遍语法，正式进入 Aiken 的表达式世界。
