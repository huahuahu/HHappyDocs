# 打包、TestFlight、App Store 提审与手动发布

下面按 `asc 2.6.0` 的本地 help 编写，执行时仍重新查帮助。所有远端调用必须加主技能的完整代理前缀；表格中的命令是参数指引。使用本次回读得到的 `APP_ID`、`VERSION`、`BUILD`、`VERSION_ID`、`BUILD_ID`、`GROUP_ID`，不要复制历史回执中的 ID。

## 先决定复用、等待还是新建 build

先查询目标版本的 build 和上传记录，并核对发布记录中的源码与制品对应关系：

- 已有 App、marketing version、源码对应且可用于目标渠道的有效 build：回读精确 `BUILD_ID`，确认 `processingState=VALID`；TestFlight 分发还须确认未过期。直接复用，跳过 build 递增、归档、导出和上传，进入 TestFlight 状态核验或正式版本准备。只改商店文案、截图、审核备注也走这条分支。
- 匹配的 build/upload 仍在处理：继续等待和查询同一上传，不重新上传。处理成功后进入复用分支；失败则先诊断原因。
- 需要新二进制（包括源码变化或新 marketing version），且没有相符的已上传 build：按版本指南确定可用 build 号后执行归档和上传。如果已有对应的、尚未上传的 archive/IPA，先核验其身份、源码及制品记录，符合要求即可复用本地制品，跳过重复归档和导出。

“继续提审”不意味着重新打包。不能只因 build 状态为 `VALID` 就认为源码匹配，也不能把另一个 marketing version 的 build 绑定到本次版本。

## 签名归档和 IPA（仅需要生成新制品时）

先执行版本指南中的准备和验证。构建操作按主技能的 `xcode` MCP → XcodeBuildMCP → 直接工具顺序；原生 archive/export 能力不可用时才用下列 `asc xcode` 包装或 `xcodebuild` fallback。使用 Release、scheme `HDiary`、generic iOS 真机目标；Debug/Simulator 产物不能上传。

保存到 `build/releases/<version>/<build>/` 等被忽略目录，每个 build 独立，保留 dSYM。检查当前签名 team、证书、profiles、App 和 Widget Bundle ID、App Groups、CloudKit 容器与 Production entitlement。历史 team ID 或 ExportOptions 是参考，不是本次验证结果。CloudKit 数据模型若有变更，检查生产 schema 是否已具备；未部署时说明阻塞，不自动修改生产数据。

可以从 `release/1.16/ExportOptions.plist` 派生新版本的配置：`method=app-store-connect`、`destination=export`、`manageAppVersionAndBuildNumber=false`。本地导出便于先校验再上传，避免 archive/export 已直传后重复 upload。

仅当需要上述 fallback 且依赖/签名资料已本地具备时：

```sh
asc xcode archive --project "$REPO_ROOT/HDiary.xcodeproj" --scheme HDiary --configuration Release --archive-path "$ARTIFACT_DIR/HDiary.xcarchive" --xcodebuild-flag=-destination --xcodebuild-flag=generic/platform=iOS --xcodebuild-flag=-onlyUsePackageVersionsFromResolvedFile --output json
asc xcode export --archive-path "$ARTIFACT_DIR/HDiary.xcarchive" --export-options "$RELEASE_DIR/ExportOptions.plist" --ipa-path "$ARTIFACT_DIR/HDiary.ipa" --output json
```

需要下载包或 `-allowProvisioningUpdates` 联网更新签名时，加完整代理前缀。发生 SwiftPM bare-repository 错误时按主技能使用单次配置覆盖，不改全局配置。

解包最终 IPA，检查 App 和每个 Widget appex 的 Bundle ID、`CFBundleShortVersionString`、`CFBundleVersion`，核对签名和实际 entitlements；记录 archive、IPA、dSYM 与 source commit 的对应关系及校验和。确认 Release 不包含截图测试入口。对本次涉及的系统框架兼容性、隐私 manifest/required reason API 和真机特有行为做针对性检查，不把历史 build 的检查记录当作当前证据。

## TestFlight

TestFlight 使用上传到 ASC 的 build，不需要再创建一个叫“TestFlight 版本”的 App Store version。按上面的分支选择 `BUILD_ID`；复用远端 build 时跳过下表的上传行，只核验和补齐尚未完成的测试说明、组关联或 Beta 审核，不重复提交已完成或仍在进行的审核。完整发布应选择可用于 App Store 的分发方式，不能上传标记为仅内部 TestFlight 测试的包。同一符合条件的 build 通过测试后可直接用于正式提审。

| 步骤 | 当前命令参数或动作 | 成功证据 |
| --- | --- | --- |
| 仅上传尚未上传的新包 | `asc builds upload --app "$APP_ID" --ipa "$IPA_PATH" --wait` | 上传回执、匹配版本/build 的远端 `BUILD_ID` |
| 检查处理 | `asc builds info --build-id "$BUILD_ID"` | `processingState=VALID`，非 expired，App/version/build 匹配 |
| 测试说明 | `asc builds test-notes --help`，选择 list/create/update | zh-Hans/en-US 的 What to Test 正确，不与 What's New 混用 |
| 分发前检查 | `asc validate testflight --app "$APP_ID" --build "$BUILD_ID"` | 处理、测试说明和 Beta 审核资料已满足目标测试渠道 |
| 测试组 | `asc testflight groups list --app "$APP_ID" --paginate`，然后 `asc builds add-groups --build-id "$BUILD_ID" --group "$GROUP_ID"` | 已关联预期内部或外部组 |
| 外部 Beta 审核 | 确认外部测试在范围内后，使用 `asc builds add-groups --build-id "$BUILD_ID" --group "$GROUP_ID" --submit --confirm` | Beta review 回执；不把提交当作已可测试 |
| 回读可用性 | `asc builds build-beta-detail view --build-id "$BUILD_ID"`，必要时 `asc builds beta-app-review-submission view --build-id "$BUILD_ID"` | 区分内部和外部状态，外部测试须已获相应批准并可用 |

What to Test 包含新功能入口、关键回归路径、设备/系统关注点和已知限制。沿用已配置的目标组；多个组无法推断时询问组选择，同时继续准备。不要自行创建测试者或开启公开链接。缺少 Beta App Review 联系信息或登录演示条件时按真实资料补齐，密码和验证码留在用户终端。

等待 processing 时用有超时的轮询，工具异步运行时继续其他工作并汇报。网络超时先查 build/upload 状态；`FAILED/INVALID` 先诊断，处理中的同一包不重复上传。只有实际用 TestFlight 安装并验证过才报告安装验证通过；`IN_BETA_TESTING` 证明分发状态，不证明人工测试已完成。用户要求“测试通过后再提审”时必须取得对应测试结果才进入正式提交。

## 准备 ASC 版本和 localizations（上传截图之前）

仅在准备正式 App Store 版本的范围内执行本节；仅 TestFlight 请求不需要创建正式版本。读取现有 App/版本状态，避免重复创建；已有目标版本正在审核时先检查，不能自动撤回或覆盖。本节只建立后续上传截图需要的版本和语言资源，不以截图已上传或完整提审校验通过为前提。

- 从当前线上版本/已准备目标版本拉取 canonical metadata，保存本次备份后再修改。继承旧版本资料时，将待发布的版本字段放到 `metadata/version/<目标版本>/`，不要仍指向旧版子目录。What's New 根据实际 Git 差异写中英文，描述、关键词等仅在功能变化需要时更新。支持与隐私 URL 验证真实公开页面可达，存储服务存在文件不等于 URL 可用。
- 在 `release/<version>/metadata/` 下离线验证：`asc metadata validate --dir "$RELEASE_DIR/metadata"`。发布 staging 使用其中 `version/<version>` 子目录。

对新版本显式创建 `MANUAL`；已有版本设置并回读手动策略。创建前先 list/定位版本，确认不存在才 create，记录本次得到的 `VERSION_ID`：

```sh
HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 asc versions create --app "$APP_ID" --version "$VERSION" --platform IOS --release-type MANUAL
```

在已存在的目标版本上应用本次元数据，以创建或更新目标 localizations。先预览下列命令，核对 App、版本、语言和字段后，在已有准备授权内移除 `--dry-run` 执行；不添加 `--allow-deletes`。App-info 文件只包含本次准备应用的字段，避免顺带覆盖其他资料；所需 scope 和参数遵循 metadata 技能及当前 help。

```sh
HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 asc metadata apply --app "$APP_ID" --version "$VERSION" --platform IOS --dir "$RELEASE_DIR/metadata" --dry-run
```

应用后，用 `asc localizations list --version "$VERSION_ID" --paginate --output json` 回读目标版本的 `zh-Hans` 和 `en-US` 记录，保存 locale 到 `data[].id` 的映射。该网络调用同样加完整代理前缀。缺少任一目标 locale 时先补齐并回读，不能拿旧版本的 ID 上传截图。`asc release stage` 包含完整准备度校验，放到截图上传之后；不用它作为创建 localizations 的前置依赖。

## 上传截图、绑定 build 与最终校验

版本和 localizations 已核验后，按 [截图流程的上传部分](screenshots.md#上传和远端验证) 操作本次目标集合，等待全部素材为 `COMPLETE`，核对数量、顺序和 checksum；沿用截图也须回读验证。

- 核对选定 build `VALID` 且版本匹配，补齐年龄分级、版权/内容权利、加密声明、审核联系人和必要的演示账号、备注、App Privacy 发布状态、定价与可售区域。遵循真实功能/数据处理情况，不编造声明来消除警告。
- 有新增/变化的 IAP 或订阅时检查产品元数据、定价和首审关联；已有产品不做无关改价。公有 API 无法核验的 App Privacy 等项目用现有网页能力核实，不能由 `asc validate` 通过推断它们都正确。

对该精确版本执行 `asc release stage --app "$APP_ID" --version "$VERSION" --build "$BUILD_ID" --metadata-dir "$RELEASE_DIR/metadata/version/$VERSION" --dry-run`，检查计划后在已有准备授权内用 `--confirm` 应用，绑定选定 build 并进行完整准备度校验。此时目标版本与 localizations 已存在，元数据已应用，预期计划应复用这些资源；若计划意外创建另一版本或覆盖非本次字段，先校正目标和本地资料。stage 的 version 子目录不会替代 App-info 更新。

stage 完成后、正式提交之前，显式设为手动并回读：

```sh
HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 asc versions update --version-id "$VERSION_ID" --release-type MANUAL
HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 asc versions view --version-id "$VERSION_ID" --include-build --include-submission --output json
```

只有回读 `releaseType=MANUAL`、版本和 build 绑定均正确才继续。`AFTER_APPROVAL` 是自动发布，`SCHEDULED` 是定时发布，都不满足本流程要求；phased release 也不能代替手动发布。不要使用会绕过此检查的上传加提审一条龙命令。

## 正式提交和提交后的强制回读

1. 运行 `asc validate --app "$APP_ID" --version-id "$VERSION_ID" --platform IOS --output json`。处理真实阻塞；若有 CLI 与 Apple 规则不一致的诊断，逐项依据当前远端数据和 Apple 文档核实并记录，不把 1.16 的历史误报作为通用跳过理由。
2. 运行 `asc review submit --app "$APP_ID" --version-id "$VERSION_ID" --build "$BUILD_ID" --dry-run` 并检查目标。若用户只要求准备，就交付已核验的准备结果；用户已授权提审则直接执行以下正式步骤，不重复索要确认：

   ```sh
   HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 asc review submit --app "$APP_ID" --version-id "$VERSION_ID" --build "$BUILD_ID" --confirm
   ```

3. 保存 submission ID 后，**再次**执行上面的 `versions view`，并运行 `asc submit status --id "$SUBMISSION_ID"`（或 `--version-id "$VERSION_ID"`）。保存带时间的回读：正确 App、version、build、submission，以及 `releaseType=MANUAL`。版本状态可为 `WAITING_FOR_REVIEW` 或其后续审核状态；`READY_FOR_REVIEW`/仅 Add for Review 或 dry run 不能写成已正式提审。分别保留版本状态和 submission 原始状态，不能假设它们使用相同枚举。
4. 若提审后策略意外不是 `MANUAL`，立刻尝试对同一版本修正并回读。若当前状态禁止修改，报告真实状态和 Apple 错误，说明手动发布尚未保证；不静默声称完成，也不自动撤回审核或切换为自动发布。
5. 超时或断线时先查询是否已有本次 submission；存在就继续跟踪，不重复提交。审核被拒时保存原因，区分只改 metadata 与必须增加 build 的情况；修改二进制需重复包校验和测试。

使用当前 API 的 `appVersionState`；旧 CLI 若只提供 `appStoreState`，记录其原始字段。手动策略获批后通常进入 `PENDING_DEVELOPER_RELEASE`，此时按 [tag 规则](version-and-tags.md) 固定最终发布源码，并停在等待上线。只有用户明确要求现在发布，才查 `asc versions release --help` 执行对应手动 release，再核验远端状态与商店可用性。release 请求成功与商店传播完成分别报告。

Apple 字段依据（通过 sosumi 获取，执行时有疑问应重查）：[releaseType 更新枚举](https://developer.apple.com/documentation/appstoreconnectapi/appstoreversionupdaterequest/data-data.dictionary/attributes-data.dictionary)、[版本状态字段](https://developer.apple.com/documentation/appstoreconnectapi/appstoreversion/attributes-data.dictionary)。
