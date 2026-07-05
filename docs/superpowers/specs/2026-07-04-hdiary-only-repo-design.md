# HDiary-only repository cleanup design

## 目标

把当前从 iOS mono repo 复制来的内容裁剪成 HDiary-only 项目仓库，同时保留 HDiary 的日常开发、构建、测试、发布和 agent skills 配置。裁剪后仓库不再保留其他 app 的源码、Xcode project、网站页面或专用脚本。

## 保留范围

保留以下内容：

- `MonoRepos/HDiary/`：HDiary app、widget、tests、`HDiaryLibrary` Swift package、release metadata 和 IAP 文档。
- `HSharedCode/`：`HDiaryLibrary` 通过 `../../../HSharedCode` 依赖的共享 Swift package。
- `websites/hdiary/`：HDiary 官网和隐私页。
- 根目录基础配置：`.gitignore`、`.swiftformat`、`.swiftlint.yml`、`build.xcconfig`、`buildServer.json`、`makefile`。
- HDiary 相关的 CI、构建、测试、发布脚本和文档。
- `.agents/skills/` 和 `skills-lock.json`：项目级 agent skills 配置。

删除以下内容：

- 非 HDiary app 目录：`MonoRepos/AppStoreArtWork`、`MonoRepos/ClipboardInspector`、`MonoRepos/ExifViewer`、`MonoRepos/HAgility`、`MonoRepos/HDoc`、`MonoRepos/Learn`、`MonoRepos/libai`、`MonoRepos/SharedCode`。
- 非 HDiary 网站：`websites/hdoc`，以及只服务其他 app 的网站入口内容。
- 当前 `Pods/`、`Podfile`、`Podfile.lock`：现有 Podfile 只配置 HAgility，和 HDiary 无关。
- 明显只服务 HDoc 或其他 app 的 docs、scripts、build artifacts。

## 配置改写

`MonoProjects.xcworkspace/contents.xcworkspacedata` 改成只引用：

- `MonoRepos/HDiary/HDiary.xcodeproj`
- `HSharedCode`

CI 和脚本改写目标：

- `azure-pipelines.yml` 只保留 HDiary build/test steps。
- `ci/src/lib/XcodeProject/ProjectName.ts` 只保留 HDiary app、`MonoRepos/HDiary/HDiaryLibrary` 和必要的 shared package project definitions。
- `ci/project.json` 只保留 HDiary 相关 target。
- `makefile` 保持 `TARGET ?= HDiary`，并确保 build/test 脚本仍以 HDiary 为默认目标。
- 删除或改写 HDoc 专用 TestFlight 文档和 `build_and_upload_testflight.sh`，避免保留指向 `MonoRepos/HDoc` 的坏引用。

## 不改动的边界

- 不移动 `MonoRepos/HDiary` 到仓库根目录，避免大规模 Xcode/SwiftPM 路径调整。
- 不重写 HDiary app 的 bundle id、signing、CloudKit、IAP 或 localization。
- 不提交任何更改，除非用户另行明确要求。

## 验证

完成裁剪后执行以下检查：

1. `npx skills list --json` 能列出项目 skills。
2. `MonoProjects.xcworkspace/contents.xcworkspacedata` 不再引用非 HDiary project。
3. 搜索 `HDoc`、`HAgility`、`ClipboardInspector`、`ExifViewer`、`Learn`、`libai` 等名称，确认没有保留在 workspace、CI、scripts、docs 的活跃引用中。
4. 使用 XcodeBuildMCP 检查可用 scheme，并尝试构建 HDiary。若本机签名、依赖或环境导致构建失败，报告具体阻塞原因。

## 成功标准

- 仓库内容只剩 HDiary 产品、HDiary 依赖、HDiary 网站、HDiary 工程化支持和项目 agent skills。
- Xcode workspace、CI、脚本、文档不再指向已删除的其他 app。
- HDiary 的 Swift package 路径依赖保持有效。
- 工作区没有临时 `.codebuddy` symlink 或安装中间产物。
