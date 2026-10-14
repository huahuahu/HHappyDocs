# Bump version、build 和 Git tag

在仓库根目录执行本地命令。网络参数示例执行前遵循主技能的完整代理前缀。

## 版本与 build 是两个值

权威来源是 `HDiary/Configs/base.xcconfig`：

| 配置 | 包内字段 | 何时修改 |
| --- | --- | --- |
| `MARKETING_VERSION` | `CFBundleShortVersionString` | 新 App Store 版本；例如 `1.16 → 1.17`，小修复可以是 `1.16.1` |
| `CURRENT_PROJECT_VERSION` | `CFBundleVersion` | 每次需要上传新二进制；同一版本返工时保持 marketing version，递增 build |

1. 读取当前配置、目标版本的远端 build（包含处理中的上传），不要把历史示例 `1.16 (2)` 当作现状。
2. 用户已指定版本则遵循；否则根据实际变更和仓库习惯选下一版本并说明。不能用字符串比较版本，例如 `1.10` 比 `1.9` 新。
3. 使用当前 CLI 计算远端安全的 build 号：

   ```sh
   HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 asc builds next-build-number --app "$APP_ID" --version "$VERSION" --platform IOS --output json
   ```

   同时核对本地是否已有预留/归档的 build。新 marketing version 可从 `1` 开始，但须以远端和上传记录确认可用；同版本换二进制必须增加。仅改截图、What's New 或审核备注可复用现有有效 build。
4. **只修改源 xcconfig 中这两个值**，检查所有配置是否有覆盖。不要全仓库替换旧版本文字，也不要运行会改生成工程的 `asc xcode version edit` 或 `agvtool`。

   ```sh
   rg -n 'MARKETING_VERSION|CURRENT_PROJECT_VERSION' HDiary/Configs project.yml
   ./scripts/generate-project.sh
   git diff -- HDiary/Configs/base.xcconfig
   ```

5. 按主技能的 MCP 顺序读取最终 Release build settings，核对 HDiary 与 Widget 的两个值一致。运行本次变更必要的现有测试、Release 构建和真实运行检查；明确用户豁免项，失败和未执行项分别记录。截图测试不替代实际交互。
6. 新建 `release/<version>/`，只带入可复用的资料模板并更新内容；不要整目录复制旧 `status.json`、submission 回执或个人资料。签名导出选项保留 `manageAppVersionAndBuildNumber=false`，避免导出时悄悄改 build。
7. 在已授权的发版工作中提交本次源文件和版本改动，记录不可变的 `sourceCommit`，然后从此状态归档。现有 dirty 工作先隔离；不擅自提交无关改动。后续若因截图入口或其他原因修改源码，重新提交、验证并更新 `sourceCommit` 后才能归档。归档后从实际 `.app/Info.plist` 和 `PlugIns/*.appex/Info.plist` 再次核验版本和 Bundle ID，不能只读源码配置。

## Tag 决策

Git tag 用来追溯发布源码，不是 Apple 上传或提审的必要条件。默认沿用仓库的 annotated tag 命名 `v<marketing-version>`。

| 情况 | 操作 |
| --- | --- |
| 只准备、只上传 TestFlight，或仍在审核可能换包 | 默认暂缓正式 `v<version>`，在发布记录写明原因 |
| 最终 build 审核通过，等待手动发布；或已确认上线 | 为最终发布源码创建 `v<version>`，已有正确 tag 则复用 |
| 用户明确要求提审后立即打 tag | 记录这是提审候选，明确其 build 与 source SHA；后续换包不移动该 tag |
| 同 marketing version 的测试 build 迭代 | 不为每次迭代创建正式版本 tag；需要追踪且用户要求时用 `v<version>-build.<build>` |
| 同名 tag 已存在但指向不符 | 停止 tag 写入，报告差异并处理命名；不 `--force`、不删除重建 |

这是项目推荐时机，不是 Apple 要求。用户已要求创建/推送 tag 或完整发布收尾时，按已有授权执行；只问“要不要 tag”时解释规则，不因此推送。

### Tag 必须能对应上传的二进制

- 默认指向生成最终 archive 的 `sourceCommit`，不要用执行到这一刻的任意 `HEAD`。
- 若希望 tag 指向后续发布资料提交或 squash merge commit，先比较全部制品相关输入：App、Widget、所有本地 Swift package、资源、配置、`project.yml`、根及本地包 lockfile。只有这些内容与归档源码一致，才可选该提交；记录原 `sourceCommit` 和最终 `tagCommit`。
- PR 合并不自动证明源码等价。没有合并授权就保留 PR 状态，不为打 tag 自动合并；仓库确有“仅在主分支打 tag”规则时，等待满足规则。
- 创建前检查本地与远端同名 tag 和 annotated tag 的 peeled commit。网络超时先查询，不重复盲推。已有远端 tag 正确则记录并结束。

在变量已验证、tag 不存在且创建/推送阶段已授权时：

```sh
git tag -a "v$VERSION" "$TAG_COMMIT" -m "HDiary $VERSION (build $BUILD)"
git rev-parse "v$VERSION^{commit}"
HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 git push origin "refs/tags/v$VERSION"
HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 git ls-remote --tags origin "refs/tags/v$VERSION" "refs/tags/v$VERSION^{}"
```

只推这个 tag，不使用 `git push --tags`。在发布记录保存本地 tag、远端验证、`sourceCommit`、`tagCommit`、对应 build 和核验时间。GitHub Release 是另一项可选产物，不由创建 tag 自动推导。
