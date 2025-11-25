# 05 · Project Structure & CLI

> 彻底弄懂 `aiken.toml`、构建产物与 CLI 命令群。跑一遍 `check`、`build`、`docs`、`blueprint`，知道每个文件/命令作用何在。

---

## 学习目标
1. 全面认识 Aiken 项目的目录：`lib/`、`src/`、`validators/`、`test/`、`build/` 等。 
2. 熟练使用 `aiken check`、`aiken build`、`aiken blueprint ...`、`aiken docs`、`aiken fmt`、`aiken lsp`。 
3. 理解 `plutus.json`、`uplc/`、`blueprint.json`、`docs/`、`aiken.lock` 的用途以及何时需要提交到仓库。

## 开始前贴士
| 步骤 | 命令/动作 | 说明 |
| --- | --- | --- |
| 打开目录 | `cd /Users/zekai/Documents/Cardano/Cardano-Aiken/05_ProjectStructureAndCLI` |
| 运行 `check` | `aiken check`（会执行 `test/main.ak` 中的示例断言） |
| 运行 `build` | `aiken build --trace-level verbose`（将生成/更新 `plutus.json`） |
| 生成 doc/blueprint | `aiken docs`（生成 ./docs）、`aiken build`（生成 plutus.json 与 blueprint，当前示例没有额外 validator） |

## 文件速览
| 文件/目录 | 作用 |
| --- | --- |
| `README.md` | 解释 CLI 命令与目录结构，也是你现在看到的内容 |
| `aiken.toml` | 项目清单，指定 `cardano_aiken/lesson05`、Plutus 版本、描述信息 |
| `src/main.ak` | 最小 validator 函数，供 CLI 构建与测试 |
| `test/main.ak` | 执行 `main` 的简单断言，示范 `aiken check` 的输出 |
| `plutus.json`、`build/`、`docs/` | CLI 生成的构建产物。根据团队策略决定是否纳入版本控制（通常 `plutus.json` 会提交，`build/` 可忽略，`docs/` 视需求而定）。 |

---

## 1. 目录树速览
```
05_ProjectStructureAndCLI/
├── README.md
├── aiken.toml
├── src/main.ak
├── test/main.ak
├── build/
│   ├── aiken-compile.lock
│   └── packages/packages.toml
├── plutus.json
└── docs/ (运行 `aiken docs` 后生成)
```

- `src/main.ak` + `test/main.ak` 是本讲实际运行的示例。
- `build/` 与 `plutus.json` 是 CLI 自动生成的构建产物；一般不手动编辑。
- `docs/` 需要运行 `aiken docs` 才会出现，用于浏览器查看 API 文档。

---

## 2. CLI 命令卡片
| 命令 | 作用 | 示例输出片段 |
| --- | --- | --- |
| `aiken check` | 编译所有模块 + 执行测试 | `Compiling cardano_aiken/lesson05 ... Collecting all tests` |
| `aiken build --trace-level verbose` | 生成 `plutus.json`、`uplc/`，可加 `--out` 指定路径 | `Generating project's blueprint (./plutus.json)` |
| `aiken blueprint address --module foo --validator bar` | 计算脚本地址 | 当前示例只有成功测试脚本，不额外导出 validator，后续章节会实际使用 |
| `aiken docs` | 生成 `docs/` HTML | 命令结束后提示 `Writing documentation to ./docs` |
| `aiken fmt` | 格式化 `.ak` 文件 | 回车即按默认风格格式化，无额外输出 |
| `aiken lsp` | 语言服务器，可供 VS Code 扩展使用 | 启动后等待编辑器连接 |

> 贴士：VS Code 用户可以安装官方 `Aiken` 扩展，启用 `aiken lsp` 后即可获得语法高亮、自动补全与诊断。

---

## 3. 示例代码：最小 validator

`src/main.ak`
```gleam
use aiken/builtin.{Data}

/// 最小示例：永远返回 True。
pub fn main(_datum: Data, _redeemer: Data, _context: Data) -> Bool {
  True
}
```

`test/main.ak`
```gleam
use aiken/builtin.{Data}
use aiken/test
use cardano_aiken/lesson05.{main}

test fn always_true() {
  let dummy = Data::Bytes(#[])
  expect True = main(dummy, dummy, dummy)
}
```

---

## 4. CLI 实战：一步到位
```
$ cd /Users/zekai/Documents/Cardano/Cardano-Aiken/05_ProjectStructureAndCLI
$ aiken check
    Compiling cardano_aiken/lesson05 0.1.0 (.)
    Resolving dependencies
   Collecting all tests scenarios across all modules
$ aiken build --trace-level verbose
    Compiling cardano_aiken/lesson05 0.1.0 (.)
   Generating project's blueprint (./plutus.json)
$ aiken docs
   Generating documentation for cardano_aiken/lesson05 0.1.0 (.)
      Writing documentation files to ./docs
```

---

## 5. 练习
| 练习 | 操作 | 验证方式 |
| --- | --- | --- |
| 修改项目名 | 在 `aiken.toml` 改 `name = "yourname/lesson05"`，再运行 `aiken build` | `plutus.json` 中的 `title` 会同步更新 |
| 自定义输出目录 | `aiken build --out dist/lesson05.json` | 查看 `dist/lesson05.json` 内容 |
| 格式化 & LSP | 在 `src/main.ak` 随意缩进，运行 `aiken fmt`；或启动 `aiken lsp` 并使用 VS Code | `aiken fmt` 无错误即可，LSP 会在编辑器提供补全 |

---

## 6. Troubleshooting
| 问题 | 可能原因 | 解决方案 |
| --- | --- | --- |
| `I couldn't find any 'aiken.toml'` | 在仓库根运行命令 | 先 `cd` 到讲次目录再执行 CLI 命令 |
| `unknown module cardano_aiken/lesson05` | `aiken.toml` 的 `name` 与 `use` 路径不一致 | 保持 `name` 与命名空间（`cardano_aiken/lesson05`）一致 |
| `validator_arity` 报错 | validator 参数数量不符 | 检查 handler 是否提供了正确数量的参数（如 `main` 需三个 Data） |

---

## 7. 延伸阅读
- [Aiken CLI 官方文档](https://aiken-lang.org/cli)
- [Aiken Blueprint 规范](https://aiken-lang.org/blueprint)
- [VS Code Aiken 扩展](https://marketplace.visualstudio.com/items?itemName=AikenLang.aiken-vscode)

下一讲将把 CLI 与测试结合，深入 `06 · Unit Testing Basics`。
