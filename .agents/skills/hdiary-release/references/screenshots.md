# HDiary App Store 截图

从当前源码的 [AppStoreScreenshotFixture](../../../../HDiaryLibrary/Sources/HDiaryAppFeature/Preview/AppStoreScreenshotFixture.swift) 和最近发布目录开始。历史参考是 [1.16 截图复现记录](../../../../release/1.16/README.md) 与 [合成脚本](../../../../release/1.16/compose-screenshots.py)，不要把旧图直接宣称为本次新截图。

## 拍摄范围与原图

默认保持 `zh-Hans`、`en-US` × iPhone、iPad 四组，每组五个不同功能页面：

| 顺序 | 页面参数 | 主题 |
| --- | --- | --- |
| 01 | `moments` | light |
| 02 | `detail` | light |
| 03 | `participants` | light |
| 04 | `tags` | light |
| 05 | `chart` | dark |

沿用四浅一暗、橙色标题和手绘太阳的现有风格；用户指定设计或新功能需要替换页面时按实际内容调整。App Store 的这组静态截图不会跟随用户系统外观切换。同一组不要靠同一页面深浅两版凑数。

1. 重新生成工程，按主技能工具顺序构建并安装当前源码的 Debug App（当前 Bundle ID 为 `com.tiger.suzhou.HDiary-Debug`，使用前核对）。此截图入口应始终仅在 `#if DEBUG && os(iOS)` 中启用，用内存 SwiftData、虚构数据和禁用的 CloudKit；不触碰真实用户记录。
2. 从 YAML 选定的 iPhone Simulator 开始；需要 iPad 图时记录额外选用的具体 iPad UDID、设备型号和 OS，切换工具上下文后拍摄，最后恢复原配置。不要用模糊的 `booted` 或把 iPhone 图拉伸成 iPad 图。
3. 通过工具的 App 启动参数传入以下值，每页修改 page，按矩阵修改 locale/appearance：

   ```text
   -HDiaryStoreScreenshots YES
   -HDiaryScreenshotPage moments
   -HDiaryScreenshotLocale zh-Hans
   -HDiaryScreenshotAppearance light
   -AppleLanguages (zh-Hans)
   -AppleLocale zh_CN
   ```

   英语分别用 `en-US`、`(en)`、`en_US`。确认 scheme 没有在末尾追加冲突语言参数；优先使用已安装 App 的单独启动能力。不要以 `-e AppleLanguages` 代替启动参数。
4. 设置一致的状态栏（9:41、满电、不充电），记录拍摄日期和样例时间。等待 UI 层级和截图都出现目标页面业务内容再保存；启动返回成功或固定 sleep 不证明界面就绪。
5. 优先让 MCP 保存原生像素 PNG。检查实际文件尺寸，工具回传预览可能已缩小。若两个 MCP 都不能导出原生像素文件，才使用 `xcrun simctl io "$SIMULATOR_ID" screenshot "$OUTPUT_PNG"`；记录降级原因。不能放大低分辨率预览充当原图。

当前合成脚本要求 iPhone 原图 `1206×2622`、iPad 原图 `2064×2752`，输出 iPhone `1242×2688`、iPad `2064×2752`，均为无 alpha 的 RGB PNG。当前配置或 Apple 尺寸规范变化时，以实测和 `asc screenshots sizes` 为准，适配**新版本目录**的合成脚本；不要为了绕过尺寸检查直接拉伸截图。

## 合成和视觉验收

把既有合成脚本复制到 `release/<version>/compose-screenshots.py` 并更新脚本说明、页面文案、HTML 标题中的版本字样。它以脚本所在目录作为输入/输出根目录；不能在旧目录运行然后覆盖旧版资料。需要 Python Pillow 和 `rsvg-convert`，先检查现有环境，安装时遵循代理规则。

原图分别放在：

- `release/<version>/screenshots/raw/<locale>/<device>/01-moments.png` 等：浅色。
- `release/<version>/screenshots/dark/raw/<locale>/<device>/05-chart.png` 等：深色。

两种可行的采集方式：完整拍摄浅/深各二十张后合成；或只拍最终需要的十六张浅色和四张深色，分别用 `--allow-partial` 合成。第二种方式只是中间合成允许部分输入，最终 `mixed` 和验收仍必须二十张齐全。

```sh
python3 "release/$VERSION/compose-screenshots.py" --theme light --allow-partial
python3 "release/$VERSION/compose-screenshots.py" --theme dark --allow-partial
python3 "release/$VERSION/compose-screenshots.py" --theme mixed
asc screenshots validate --path "release/$VERSION/screenshots/mixed/store/zh-Hans/iphone" --device-type IPHONE_65
```

对四组分别做本地 validate（iPad 的现有类型为 `IPAD_PRO_3GEN_129`），逐张打开原图、成品和 `mixed/review.html` 或总览检查：真实目标页面、语言正确、头像首字正常、照片与背景正确、文案无截断、图表完整、深浅主题正确。仅检查图片能解码不算视觉验收。合成只能添加文案、品牌和外框，不重绘应用内容。

保存 raw manifest 与成品 manifest：源码 SHA、版本/build、设备/OS/UDID、locale、page、appearance、像素尺寸、源文件与成品 SHA-256。最终检查每组恰好五张、编号顺序正确、内容不同，四组齐全。`--allow-partial` 不能作为缺图的最终豁免。

## 上传和远端验证

本地拍摄、合成和验收可先完成；远端上传必须等 [打包与提审指南](distribution.md) 中的 ASC 版本和 localizations 准备完成后执行。先确认目标版本已存在、`releaseType=MANUAL`，并从该版本回读 `zh-Hans`、`en-US` 的 localization ID。缺少资源时返回版本准备步骤补齐，不使用旧版本 ID，也不要求先上传截图才能创建资源。

使用精确目标版本的 localization ID，它不是 `zh-Hans` 这样的语言代码。先查询远端已有集合并保存清单；确认本地完整成品后才更新目标版本的目标集合。只操作本次版本，不清理线上旧版本或无关可选尺寸。全部截图上传并回读验证后，返回发布指南绑定 build、执行 staging 和提审校验。

按 [asc-shots-pipeline](../../asc-shots-pipeline/SKILL.md) 使用 plan/apply，或分四组执行 `screenshots upload`；参数先查 help。`--replace` 会先删除集合内全部旧图，必须先核对目标、保留可恢复素材并查看 dry run；普通重试不能自动扩大删除范围。上传超时先查回执、集合与 checksum，避免重复追加超过每组上限。

逐集合回读语言、device type、数量、顺序、文件校验值和 `assetDeliveryState.state=COMPLETE`。远端常用 MD5 `sourceFileChecksum`，按 API 实际算法计算对比，不拿本地 SHA-256 与 MD5 直接比较。将结果存为本版本 `screenshots/mixed/remote-verification.json`，记录目标 version ID 和核验时间。

如果本次 UI 与商店图一致且用户未要求更新，可复用已有截图；仍须核验其内容、语言/设备覆盖和远端完整性，明确记录“沿用”，不能声称重拍完成。
