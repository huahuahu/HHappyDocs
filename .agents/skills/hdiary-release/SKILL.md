---
name: hdiary-release
description: 为 HHappyDocs 仓库的 HDiary 发布新版本，处理 bump version/build、App Store 截图、签名打包、TestFlight、提审、手动发布策略和 Git tag。用于“发一个新版本”“准备发版”“更新截图并提审”或继续已有发布；单独修复功能、普通截图或编辑发布技能本身不触发实际发版。
---

# HDiary 版本发布

用中文与花花虎沟通。此技能只服务当前 HHappyDocs 仓库；从当前 checkout 解析路径，不写死 worktree 路径。完成用户要求的发布阶段，并用远端回读和本地制品证明结果。

## 执行边界

- 先辨明目标：仅检查、仅准备、仅 TestFlight、正式提审，或审核后手动上线。完整发版默认串联准备、截图、打包、TestFlight 和提审，**发布策略固定为 `MANUAL`，提审后不自动上线**。用户明确缩小范围时只执行对应阶段。
- 用户当前会话已授权的阶段直接推进；不要每一步重复索要许可。缺少必须的信息时先完成独立工作，只问影响下一步的具体问题。创建或修改此技能不意味着实际发版。
- 不把“提交审核”解释为“审核通过后立即发布”。只有用户另行明确要求现在上线，才执行手动 release。也不因发版自动邀请新测试者、发消息或邮件、合并 PR、取消已有审核、改生产 CloudKit schema 或调整订阅价格。
- 旧 `release/1.16/README.md` 的 `AFTER_APPROVAL` 是历史记录，**不得沿用**；新版本必须提审前设置 `MANUAL`，提审后再次核验。

## 项目和工具约定

先读仓库 [AGENTS.md](../../../AGENTS.md)、`.xcodebuildmcp/config.yaml`、`HDiary/Configs/base.xcconfig`、最新发布目录和当前 Git 状态。App ID `6470147729`、Release Bundle ID `com.tiger.suzhou.HDiary` 只作为定位线索，每次从 ASC 回读验证 App 身份；沿用现有 App。

按需要读取本仓库配套技能，不要一次加载全部：

| 工作 | 配套技能 |
| --- | --- |
| ASC 命令、ID、处理状态 | [asc-cli-usage](../asc-cli-usage/SKILL.md)、[asc-id-resolver](../asc-id-resolver/SKILL.md)、[asc-build-lifecycle](../asc-build-lifecycle/SKILL.md) |
| 导出和签名 | [asc-xcode-build](../asc-xcode-build/SKILL.md)、[asc-signing-setup](../asc-signing-setup/SKILL.md) |
| 商店资料和截图上传 | [asc-metadata-sync](../asc-metadata-sync/SKILL.md)、[asc-shots-pipeline](../asc-shots-pipeline/SKILL.md) |
| TestFlight 和 App Store 审核 | [asc-testflight-orchestration](../asc-testflight-orchestration/SKILL.md)、[asc-release-flow](../asc-release-flow/SKILL.md)、[asc-submission-health](../asc-submission-health/SKILL.md) |

本仓库执行约定优先于通用技能的命令示例：

- `HDiary.xcodeproj` 是生成文件。新 checkout 及源文件、资源、`project.yml`、xcconfig 变化后先运行 `./scripts/generate-project.sh`，需要时安装固定版本 XcodeGen；不编辑生成的 `project.pbxproj`。保留根 `Package.resolved`。
- 构建、测试、Preview、运行、设备操作优先用 `xcode` MCP；先按 YAML 打开绝对路径工程、选择 scheme 与 destination。能力缺失、不可用或失败时使用 XcodeBuildMCP，并先展示和校准 session defaults；CLI fallback 也遵循同样上下文。两者均不能完成时才用直接工具。不要直接照抄通用截图技能中的 `simctl` 构建流程。
- ASC 优先使用 `asc` CLI；先查当前 `--help`，用明确的 App/version/build ID。网络重试前回读状态，避免重复上传、重复提审。`--dry-run` 不一定只读，例如 build upload 的 dry run 会预留上传操作。
- 所有 Bash 网络命令（包括 ASC 远端查询、上传、Git 远端操作、安装依赖）逐条加完整前缀；下文参数示例也必须补上。纯本地命令、离线验证和 `--help` 不加：

  ```sh
  HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 asc versions view --version-id "$VERSION_ID"
  ```

- SwiftPM 出现 `safe.bareRepository is 'explicit'` 时，仅为受影响命令添加 `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all`，不修改全局 Git 配置；涉及拉取时同时加代理。Apple 文档优先用 sosumi。

## 发布流程

1. **确认现状和发布范围。** 核对工作树、源码提交、已发布版本、正在审核的版本、已有 TestFlight build 和截图。保留无关改动；必要时使用隔离 worktree。已有目标版本或有效 build 就继续，不盲目新建。确定目标版本、渠道、测试组、语言和是否需要换图，并明确尚缺的内容。
2. **确定版本并固定源码。** 读 [版本号与 tag](references/version-and-tags.md)。从上一正式版本整理实际变更；继续已有发布时沿用已确定的目标版本和有效 build，只有新版本或新二进制才递增对应字段。源文件或配置变化后重新生成工程，完成与变更相关的测试及 Release 构建。记录归档对应的源码 SHA；不能从有未记录源码修改的工作树声称制品可复现。
3. **本地准备商店资料和截图。** 读 [截图流程](references/screenshots.md) 的拍摄、合成和验收部分，此阶段不上传截图。完整新版本检查截图是否仍真实、最新；用户要求更新或 UI 已变化时重新拍摄。准备 `zh-Hans`、`en-US` 的 What's New、TestFlight What to Test 和 canonical metadata；仅需变更的字段才修改。
4. **选择 build 并完成 TestFlight 阶段。** 读 [打包与提审](references/distribution.md)。若已有与目标 App、版本、源码相符且可用的 `VALID` build，复用其 `BUILD_ID`，跳过 build 递增、归档、导出和上传；若仍在处理则等待同一 build。只有需要新二进制时才选择可用 build 号、签名打包、校验并上传一次。按目标渠道补齐测试说明和测试组，分别回读内部与外部状态；已完成的分发或 Beta 审核不重复提交。仅 TestFlight 请求完成后到此交付。
5. **准备 ASC 版本并上传截图。** 在正式版本准备范围内，先创建或复用 `MANUAL` 版本，应用目标版本的元数据并回读各语言的 localization ID；随后才按截图指南上传或核验沿用截图。截图远端处理完成、审核资料和合规项就绪后，绑定选定的 `BUILD_ID`，执行 staging 和完整准备度校验。只准备、暂不提审的请求在此交付。
6. **提交审核并核验手动发布。** 提交前再次确认版本、build 和 `releaseType=MANUAL`，执行 review dry run；在已授权提审范围内正式提交。提交后再次读取目标版本、绑定 build、submission 状态和发布策略。
7. **交付、tag 与后续。** 更新本次发布记录，按 tag 规则创建或明确记录暂缓原因。完整提审的完成点是远端确认已进入审核流程且 `MANUAL` 已核验；审核结果尚未返回就如实报告。用户要求持续跟踪时使用应用提供的提醒/自动化能力，仅在状态变化或需要处理时通知。审核通过停在等待手动发布，收到上线指令后才 release 并核验商店状态。

## 留存资料和完成证据

可审阅资料放在 `release/<version>/`，沿用项目结构：

- `README.md`、`status.json`：版本/build、App/version/build/submission ID、`sourceCommit`、归档/IPA 校验和、已核验状态、`releaseType`、`verifiedAt`（带时区）、验证边界及 tag 状态。
- `metadata/`、`whats-new.<locale>.txt`、`testflight-notes.<locale>.txt`：本次版本的中英文资料。
- `screenshots/`：原图、成品、总览、manifest 和远端验证，按主题分开保存；复用旧图时记录来源与本次适用性核验。
- 本次 archive、IPA、dSYM、签名日志和含联系人的原始响应放在被忽略的 `build/releases/<version>/<build>/` 等目录；提交到 Git 的记录须脱敏。不要将密钥、账号密码或验证码写入聊天、发布目录或技能。

未知状态写“未核验”，不复制旧版本的成功回执。源码提交、发布资料、PR 合并、tag、测试、上传、TestFlight 分发、提审、审核通过、实际上线分别记录。只提交发布范围内的文件；GitHub PR 若已创建或正在继续处理，按应用要求附加到当前聊天。

最终向花花虎报告：版本/build、制品和资料位置、TestFlight 可用范围、审核状态及核验时间、`MANUAL` 回读结果、tag 指向/是否已推送，以及阻塞或待人工处理事项。不能用本地打包成功代替远端发布成功。
