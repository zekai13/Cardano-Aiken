# cardano-aiken

> 将 Cardano + Aiken 的知识体系完整打包：语言、UTxO 流程、validator 模式、blueprint、前端集成，一个仓库搞定。

## 项目定位
1. **Cardano 链上开发入门路径**：用 30 讲主线 + 安全篇 + Cardano 规则篇覆盖从语法到生产部署的全部环节。
2. **注重 CLI 与 EUTxO 思维**：每一讲都提供 `src/main.ak` 示例与 CLI 操作，强调 Datum/Redeemer/Context 设计。
3. **对标 WTF-Solidity 的阅读体验**：章节命名、目录结构、README 风格保持“讲次 + 代码/文章”格式，便于追更与引用。

## 教程指南 cardano-aiken
| 角色 | 建议操作 |
| --- | --- |
| 新手 | 按编号顺序学习，结合 `src/main.ak` 与 README 同步练习 |
| 已有 Haskell/Plutus 背景 | 直接跳到 07~18 关注 Context、Blueprint、引用输入等差异化内容 |
| 前端/后端工程师 | 阅读 05/08/29/Topics-Tools，了解 blueprint 与 off-chain 接入 |

## Star 进度条
- ⭐️ 100：发布 01–05（语言 & 工程基础）
- ⭐️ 300：发布 06–12（测试 + Context 深潜）
- ⭐️ 600：发布 13–20（引用输入、Reference Scripts、FT/NFT）
- ⭐️ 1000：发布 21–30（Demo DApp + 生产实践）
- ⭐️ 1500：发布安全篇 S01–S08 + Cardano 规则 CA01–CA06

## 使用方式
1. 本仓库遵循「每讲一个文件夹」的结构，`README.md` 提供教学脚本，`src/main.ak` 提供示例代码。
2. 克隆后直接进入目标章节，例如 `cd 01_HelloAiken && aiken check` 体验 CLI。
3. 若需阅读所有章节，可配合 GitHub Codespaces 或本地多终端窗口同时打开。

## 启动之前：必备环境 & 工具
| 步骤 | 命令/动作 | 备注 |
| --- | --- | --- |
| 安装 Aiken CLI | `curl -sSf https://install.aiken-lang.org | sh` | 安装完运行 `source $HOME/.aiken/bin/env`，再执行 `aiken --version` 验证。若网络受限，可去 GitHub Releases 下载二进制或用 Homebrew（需具备写权限）。 |
| 准备终端/编辑器 | VS Code / Terminal / iTerm | 所有命令都在章节目录下运行：`cd 01_HelloAiken`、`cd 02_LanguageTour` 等。VS Code 终端默认停在仓库根，记得手动切换目录。 |
| Git（可选但推荐） | `git clone git@github.com:...` | 管理每讲的练习结果或提交 PR。 |
| Node/npm（后续章节） | `brew install node` 或官网下载 | 08 讲以后会用来整合 blueprint、前端工具链，前几讲可暂时不装。 |
| 其他辅助 | `tree`、`lsd`、`zsh-autosuggestions` 等 | 纯增强体验，非必需。 |

> 常见错误提示：若在仓库根直接执行 `aiken build` 会提示找不到 `aiken.toml`，因为它只存在于子目录；请先 `cd` 到具体讲次。

## 01–30 主课程目录
| 章节 | 中文标题 | 英文标题 | 代码 | 文章 |
| --- | --- | --- | --- | --- |
| 第01讲 | Hello Aiken | 01_HelloAiken | [validator](./01_HelloAiken/validators/hello_aiken.ak) | [README](./01_HelloAiken/README.md) |
| 第02讲 | 语言总览 | 02_LanguageTour | [src](./02_LanguageTour/src/main.ak) | [README](./02_LanguageTour/README.md) |
| 第03讲 | 类型与模式匹配 | 03_TypesAndPatternMatching | [src](./03_TypesAndPatternMatching/src/main.ak) | [README](./03_TypesAndPatternMatching/README.md) |
| 第04讲 | 模块与标准库 | 04_ModulesAndStdlib | [src](./04_ModulesAndStdlib/src/main.ak) | [README](./04_ModulesAndStdlib/README.md) |
| 第05讲 | 项目结构与 CLI | 05_ProjectStructureAndCLI | [src](./05_ProjectStructureAndCLI/src/main.ak) | [README](./05_ProjectStructureAndCLI/README.md) |
| 第06讲 | 单元测试入门 | 06_UnitTestingBasics | [src](./06_UnitTestingBasics/src/main.ak) | [README](./06_UnitTestingBasics/README.md) |
| 第07讲 | Cardano 与 EUTxO | 07_CardanoAndEUTxO | [src](./07_CardanoAndEUTxO/src/main.ak) | [README](./07_CardanoAndEUTxO/README.md) |
| 第08讲 | Blueprint 实战 | 08_UsingBlueprint | [src](./08_UsingBlueprint/src/main.ak) | [README](./08_UsingBlueprint/README.md) |
| 第09讲 | 链上数据建模 | 09_OnChainDataModelling | [src](./09_OnChainDataModelling/src/main.ak) | [README](./09_OnChainDataModelling/README.md) |
| 第10讲 | Spending Validator 基础 | 10_SpendingValidatorsBasics | [src](./10_SpendingValidatorsBasics/src/main.ak) | [README](./10_SpendingValidatorsBasics/README.md) |
| 第11讲 | Minting Policy 基础 | 11_MintingPoliciesBasics | [src](./11_MintingPoliciesBasics/src/main.ak) | [README](./11_MintingPoliciesBasics/README.md) |
| 第12讲 | Script Context 深潜 | 12_ScriptContextDeepDive | [src](./12_ScriptContextDeepDive/src/main.ak) | [README](./12_ScriptContextDeepDive/README.md) |
| 第13讲 | Inline Datum & Reference Inputs | 13_InlineDatumAndReferenceInputs | [src](./13_InlineDatumAndReferenceInputs/src/main.ak) | [README](./13_InlineDatumAndReferenceInputs/README.md) |
| 第14讲 | Reference Scripts 实战 | 14_ReferenceScriptsInPractice | [src](./14_ReferenceScriptsInPractice/src/main.ak) | [README](./14_ReferenceScriptsInPractice/README.md) |
| 第15讲 | 简单双状态机 | 15_SimpleStateMachine | [src](./15_SimpleStateMachine/src/main.ak) | [README](./15_SimpleStateMachine/README.md) |
| 第16讲 | 时间锁与 Validity | 16_TimeLocksAndValidity | [src](./16_TimeLocksAndValidity/src/main.ak) | [README](./16_TimeLocksAndValidity/README.md) |
| 第17讲 | 多脚本项目 | 17_MultiScriptProjects | [src](./17_MultiScriptProjects/src/main.ak) | [README](./17_MultiScriptProjects/README.md) |
| 第18讲 | 错误处理与 Result | 18_ErrorHandlingAndResultTypes | [src](./18_ErrorHandlingAndResultTypes/src/main.ak) | [README](./18_ErrorHandlingAndResultTypes/README.md) |
| 第19讲 | FT Token | 19_FT_Token | [src](./19_FT_Token/src/main.ak) | [README](./19_FT_Token/README.md) |
| 第20讲 | NFT：单枚 & 系列 | 20_NFT_SingleAndCollection | [src](./20_NFT_SingleAndCollection/src/main.ak) | [README](./20_NFT_SingleAndCollection/README.md) |
| 第21讲 | NFT 固定价市场 | 21_NFT_FixedPriceSale | [src](./21_NFT_FixedPriceSale/src/main.ak) | [README](./21_NFT_FixedPriceSale/README.md) |
| 第22讲 | Escrow 合约 | 22_EscrowContract | [src](./22_EscrowContract/src/main.ak) | [README](./22_EscrowContract/README.md) |
| 第23讲 | Vesting & Lockup | 23_VestingAndLockup | [src](./23_VestingAndLockup/src/main.ak) | [README](./23_VestingAndLockup/README.md) |
| 第24讲 | Multisig 钱包 | 24_MultisigWallet | [src](./24_MultisigWallet/src/main.ak) | [README](./24_MultisigWallet/README.md) |
| 第25讲 | DAO 国库 | 25_DAOTreasury | [src](./25_DAOTreasury/src/main.ak) | [README](./25_DAOTreasury/README.md) |
| 第26讲 | 教学版 AMM DEX | 26_AMM_DEX_Edu | [src](./26_AMM_DEX_Edu/src/main.ak) | [README](./26_AMM_DEX_Edu/README.md) |
| 第27讲 | Lottery Game | 27_LotteryGame | [src](./27_LotteryGame/src/main.ak) | [README](./27_LotteryGame/README.md) |
| 第28讲 | GameFi 迷你状态机 | 28_GameFi_MiniStateMachine | [src](./28_GameFi_MiniStateMachine/src/main.ak) | [README](./28_GameFi_MiniStateMachine/README.md) |
| 第29讲 | 链上配置与参数 | 29_OnChainConfigAndParams | [src](./29_OnChainConfigAndParams/src/main.ak) | [README](./29_OnChainConfigAndParams/README.md) |
| 第30讲 | 生产级模式 | 30_ProductionReadyPatterns | [src](./30_ProductionReadyPatterns/src/main.ak) | [README](./30_ProductionReadyPatterns/README.md) |

> 尚未创建的章节会随着进度逐步补齐，链接形式保持一致，方便读者提前 bookmark。

## 安全篇 Sxx
- **S01** Logic Vulnerabilities — 防止状态短路或遗漏资产校验。
- **S02** Datum & State Pitfalls — Datum 序列化、兼容性与迁移。
- **S03** State Machine Attacks — 状态机跳跃与无效变更。
- **S04** Economic Attacks — 价格操纵、MEV、滑点保护。
- **S05** Time & Validity Pitfalls — 时间锁、valid_range 常见错误。
- **S06** Permission & Upgrade Risks — 升级流程与 owner 中心化。
- **S07** Randomness & Oracle Pitfalls — 伪随机、外部依赖安全。
- **S08** Security Checklist — 上线前审计清单。

## Cardano 规则 CAxx
1. **CA01** UTxO Model & Ledger — 从区块到 UTxO 的账本逻辑。
2. **CA02** Tx Structure & Witness — 交易结构、witness 与签名。
3. **CA03** Slots, Time & Epochs — 时间、slot、epoch 换算。
4. **CA04** Cost Model & Resources — 费用模型、CPU、内存预算。
5. **CA05** Multi-Asset & Policy — 资产策略及 policyId。
6. **CA06** Script Evaluation Flow — 验证流水线与 failover。

## Topics / Tools / NFT / Threat / Translation
- **Topics/Tools**：Aiken CLI、cardano-node、本地测试网、Blockfrost、Lucid、Mesh、TxPipe 工具包。
- **Topics/NFT**：CIP-25、CIP-68、元数据结构解析与制作流程。
- **Topics/ThreatAnalysis**：历史攻击事件拆解，定位在 EUTxO 语境。
- **Topics/Translation**：精选 Aiken/Cardano/CIP 文档翻译，以便中文社区快速跟进。

---

欢迎提 Issue/PR，一起把 Aiken 生态的中文资料做扎实。若你完成了某个章节，记得在 README 的表格中勾选 ✅，帮助后来者把握进度。

## 贡献指南
1. **Fork & Clone**：`git clone git@github.com:<you>/cardano-aiken.git`
2. **创建分支**：`git checkout -b feat/chapter-xx`
3. **实现内容**：在对应章节 README/代码里补充教程、示例或测试。需要截图/数据时可放在 `assets/`，并在 README 引用。
4. **自测**：运行 `aiken check` / `aiken build` / `aiken test`（如果适用），确保示例可复现。
5. **提交 PR**：在描述中关联章节编号，说明主要改动、测试情况、截图（如果有）。

> PR 模板与 Issue 模板会在后续补充，暂时可参考 WTF-Solidity 的写法：一句话 Summary + 改动说明 + 自测情况。
