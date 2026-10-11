# HDiary 1.16 / build 1

本次发布使用 `fa820abd600a79b0223b86e083dffd71a9ec156a` 的应用功能，更新版本号为 1.16，并加入仅供 Debug 使用的离线截图入口。商店资料为简体中文和美式英语。截图保留暖白与暗色两套素材；暗色版使用真实深色应用界面、暖黑背景、橙色标题和应用的手绘太阳图标。

## 发布标识

| 项目 | 值 |
| --- | --- |
| App ID | `6470147729` |
| Bundle ID | `com.tiger.suzhou.HDiary` |
| App Store version ID | `f08db20f-323f-4198-aa32-f2b7a4ceb59e` |
| Build ID | `b734cf6b-d385-4410-8cc2-89022f3812a9` |
| 版本 / build | `1.16` / `1` |
| 发布策略 | `AFTER_APPROVAL`，审核通过后自动发布 |

最终核验的提交状态、截图校验和及验证结果记录在 `status.json`；这是提交时的快照，后续审核状态以 App Store Connect 为准。`status-initial.json` 保留首次暖白截图提审时的原始记录。

## 资料

- `metadata/`：从线上 1.15 继承并校验的 canonical metadata。更新中英文 What's New，并将中文支持 URL 指向已有 HDiary 支持页面。
- `whats-new.*.txt`：商店更新说明。
- `testflight-notes.*.txt`：TestFlight 测试说明。
- `screenshots/raw/`：真实模拟器原图，全部使用虚构样例数据。
- `screenshots/store/`：用于上传的 20 张 PNG。
- `screenshots/review.html`：整套截图浏览页；`screenshots/preview/` 提供每组总览。
- `screenshots/manifest.json`：上传图片的尺寸、颜色模式和 SHA-256。
- `screenshots/dark/`：重新拍摄的深色原图 `raw/`、合成图 `store/`、总览 `preview/` 和浏览页 `review.html`，以及独立的原图、成品和远端校验记录。
- `screenshots/dark/capture-verification.json`：真实设备交互与视觉检查记录。
- `ExportOptions.plist`：App Store Connect 分发导出选项。

上传后的 iPhone `IPHONE_65` 和 iPad `IPAD_PRO_3GEN_129` 各有五张图、两种语言。当前已提交主题与远端状态以 `status.json` 为准。首次暖白提交的素材和校验记录保留在 `screenshots/` 根目录；暗色替换的记录位于 `screenshots/dark/`。1.16 中其他旧尺寸的截图被移除，让商店使用新版图片；线上 1.15 的截图未修改。

## 截图复现

1. 按仓库 `AGENTS.md` 运行 `./scripts/generate-project.sh`，在配置的 iPhone Simulator 上构建 Debug 版。
2. 使用 `AppStoreScreenshotFixture`，启动参数为：

   ```text
   -HDiaryStoreScreenshots YES
   -HDiaryScreenshotPage moments
   -HDiaryScreenshotLocale zh-Hans
   -HDiaryScreenshotAppearance dark
   -AppleLanguages (zh-Hans)
   -AppleLocale zh_CN
   ```

   页面依次为 `moments`、`detail`、`participants`、`tags`、`chart`。英语使用 `en-US`、`(en)`、`en_US`。`-HDiaryScreenshotAppearance` 设为 `light` 可复现原暖白截图，不传该参数时默认 light。如果 Xcode scheme 自带中文语言参数，需移除冲突参数或使用已构建 App 的单独启动能力；本次 native InstallAndRun 会在末尾重新附加 scheme 的中文参数。
3. 等待界面层级出现目标页面的业务文字，再保存截图；启动 API 返回并不表示第一帧已就绪。状态栏使用 9:41、满电且非充电状态，颜色跟随界面主题。逐张检查语言、头像首字、正文和非空白内容。
4. 保存原生像素 PNG：iPhone 17 Pro 为 `1206×2622`，iPad Pro 13-inch 为 `2064×2752`。本次 native device-interaction 的 iPhone capture 仅输出 `402×874`，MCP screenshot 会缩小图像，因此最终原图使用 `simctl io screenshot` 获取。合成脚本会拒绝尺寸不符的原图。
5. 在已具备 Python Pillow 和 `rsvg-convert` 的环境中，从仓库根目录运行：

   ```sh
   python3 release/1.16/compose-screenshots.py --theme dark
   asc screenshots validate --path release/1.16/screenshots/dark/store/en-US/iphone --device-type IPHONE_65
   asc screenshots validate --path release/1.16/screenshots/dark/store/zh-Hans/iphone --device-type IPHONE_65
   asc screenshots validate --path release/1.16/screenshots/dark/store/en-US/ipad --device-type IPAD_PRO_3GEN_129
   asc screenshots validate --path release/1.16/screenshots/dark/store/zh-Hans/ipad --device-type IPAD_PRO_3GEN_129
   ```

合成结果：iPhone `1242×2688`，iPad `2064×2752`，RGB、无 alpha。原图内容不重绘；只加入商店文案、品牌元素和设备边框。默认 `--theme light` 仍从原目录读取并合成暖白素材，`--theme dark` 使用独立的 `screenshots/dark/` 目录。

截图入口位于 `#if DEBUG && os(iOS)` 中，使用内存 SwiftData 和关闭的 CloudKit；不访问真实用户乐事，也不启动小组件快照同步。已检查上传 IPA 的可执行文件不含截图启动参数。暗色重拍只增加 Debug 截图主题参数，继续使用已上传的 1.16（1），无需重新上传二进制。

## 构建与验证边界

- Release 签名归档、App Store IPA 导出和远端处理成功，build 为 `VALID`。
- Debug 截图入口在 iPhone 和 iPad 运行，全部 20 张原图与合成图经过视觉检查。
- canonical metadata 校验通过。替换前的提审检查无阻塞项；清理旧图后，asc 2.6.0 将六个空的可选尺寸集合报告为阻塞项，但两种必需尺寸均已完整上传，Apple 的正式提交 API 接受了本次提交。最终状态以已核验的提交回执为准。既有订阅的可选推广图片提示未修改。
- 应用功能来自已通过 iOS build/test CI 的主分支提交。额外截图 CI 的最终状态记录在 `status.json`，不能将尚未结束的任务记为通过。
- 既有 Azure 支持页与隐私页的 blob 已确认存在；本机代理访问公开静态站点出现 TLS 错误，因此未将公开站点可达性记为通过。
- IPA、归档、签名日志和审核联系人响应保存在被 Git 忽略的构建目录或临时目录，不包含在发布资料中。
