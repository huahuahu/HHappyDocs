# HDiary

HDiary is an iOS app for recording happy moments.

## 开始开发

工程由 **XcodeGen 2.46.0** 生成，版本记录在 `.xcodegen-version`。使用 Xcode 27.1（Swift 6.3）及 iOS Simulator；快照测试固定使用 iPhone 17 Pro / iOS 26.5。

全新 checkout 后，在仓库根目录运行：

```bash
# 安装固定版本的官方二进制，并验证 SHA-256；只写入本仓库的 .tools/。
./scripts/install-xcodegen.sh
./scripts/generate-project.sh
open HDiary.xcodeproj
```

如果 PATH 中已经有准确的 XcodeGen 2.46.0，可以跳过安装。安装脚本使用当前 shell 的代理环境变量；生成工程不需要网络。安装或解析依赖时遵守 [AGENTS.md](AGENTS.md) 的本地网络约定。

生成 helper 会从任意工作目录定位仓库、优先使用 `.tools/xcodegen/bin/xcodegen` 并检查版本。也可直接运行 `xcodegen generate`（仓库根目录、固定版本已在 PATH 中）；`project.yml` 的生成前后 hook 同样检查版本、恢复锁文件并补齐 Widget 的 SpringBoard 调试配置。

选择 `HDiary` scheme 可运行 App 或执行原有通用测试计划；`HDiaryWidgetExtension` 保留 Widget 调试环境和宿主关系；`HDiarySnapshotHost` 使用独立的 `HDiarySnapshots` 计划。快照运行与基准维护见 [快照测试说明](HDiarySnapshotTests/README.md)。

## 构建和测试

本地 helper 会先重新生成工程，然后仅使用锁文件中的依赖版本：

```bash
./scripts/build-ios-project.sh HDiary --only-ios
./scripts/test-ios-project.sh HDiary
CONFIGURATION=Release ./scripts/build-ios-project.sh HDiary --only-ios

# 使用项目配置的模拟器；其他机器可换成自己的设备名称或 UUID。
HDIARY_DESTINATION='platform=iOS Simulator,name=hdiary 17pro' \
  ./scripts/test-ios-project.sh HDiarySnapshotHost \
  -testPlan HDiarySnapshots -parallel-testing-enabled NO
```

默认 destination 是 `iPhone 17 Pro`。可用 `HDIARY_DESTINATION` 覆盖，测试 helper 还接受额外的 xcodebuild 参数。旧的 `source scripts/build-ios-project.sh` / `buildScheme` 和 `source scripts/test-ios-project.sh` / `testScheme` 调用仍可使用。首次构建需要联网下载锁定的依赖。

## 维护工程和依赖

- 在 `project.yml` 中维护 targets、源码／资源归属、依赖和 shared schemes；修改 `HDiary/Configs/*.xcconfig` 维护构建设置。添加或移除文件后也要重新生成工程。
- `HDiary.xcodeproj/` 是忽略的生成结果，不提交或手工维护其中的文件。Xcode 中需要保留的设置应回写到上述配置。
- 根目录 `Package.resolved` 是 Xcode 工程的依赖锁定来源。每次生成后会复制到 `HDiary.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`；删除并重新生成工程不会丢失锁定版本。两个本地 Package 自己的 `Package.resolved` 继续服务独立的 SwiftPM 工作流。
- 有意更新依赖时，先生成工程，在 Xcode 中完成依赖解析和验证，然后把工程目录中的 `Package.resolved` 复制回根目录并提交。**复制前不要再次生成工程**，否则会恢复之前提交的锁。不要将普通构建产生的锁文件变化当成依赖升级。
- 测试计划仍受版本控制。XcodeGen 的 target ID 是稳定生成的；重命名 target 或升级生成器后，需同步计划中的 ID。`python3 scripts/verify-project-generation.py` 检查重复生成、target 和 scheme 引用、测试计划、StoreKit 及锁文件恢复。
- `scripts/finalize-project.py` 只补齐 XcodeGen 2.46.0 未提供的 scheme 字段：Widget 的 SpringBoard runnable、Profile 宿主，以及快照 host 的 queue debugging 设置。升级生成器时重新检查是否仍需这些兼容处理。
- 升级 XcodeGen 时一起更新 `.xcodegen-version`、`project.yml` 的最低版本和安装脚本中的官方发布包 SHA-256，再验证工程生成、Debug／Release 构建和测试。

两个 GitHub Actions 工作流都会安装同一版本并生成工程。SwiftPM 缓存键使用根目录锁文件及两个 Package manifest；快照工作流继续强制 `-onlyUsePackageVersionsFromResolvedFile`，不更新快照基准。

## Project layout

- `project.yml`、`HDiary/Configs/` — 工程结构和构建设置的来源。
- `HDiary.xcodeproj` — 生成的 app、widget 和 tests 工程（不提交）。
- `Package.resolved` — 受版本控制的 Xcode 工程依赖锁。
- `HDiary/` — HDiary app 源码、资源、StoreKit 配置和 app test plan。
- `HDiaryLibrary/Tests/` 和 `HDiaryLibrary/UITests/` — unit tests 和 UI tests。
- `HDiarySnapshotTests/`、`HDiarySnapshotHost/` — 快照测试、基准和空白宿主。
- `HDiaryWidget/` — widget extension 源码。
- `HDiaryLibrary/` — HDiary Swift package。
- `HSharedCode/` — `HDiaryLibrary` 使用的 shared Swift package。
- `release/` 和 `IAP-doc/` — release metadata 和 in-app purchase 支持文件。
- `websites/hdiary/` — HDiary website 和 privacy policy。
- `.github/workflows/ios.yml`、`.github/workflows/snapshots.yml` — 构建／测试与快照 CI。
- `scripts/` — 本地 project build/test helper。
