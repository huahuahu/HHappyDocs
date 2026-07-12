# 资料库入口卡片化实施计划

> **面向执行代理：** REQUIRED SUB-SKILL: 使用 `subagent-driven-development`（推荐）或 `executing-plans` 逐任务实施本计划。所有步骤使用复选框（`- [ ]`）跟踪。

**Goal:** 将 iOS“资料库”首页的“标签 / 参与者 / 图表”改成三张平级卡片；普通 Dynamic Type 下按可用空间选择“外部三列、内部 vertical”或“外部完整单列、内部 horizontal”，Accessibility Dynamic Type 下使用“外部完整单列、内部 vertical”，同时保留现有导航、深链和数据行为。

**Architecture:** `LibraryView` 继续拥有导航栈，并通过 SwiftData `@Query` 提供标签与参与者的实时数量；纯值型 `LibraryViewState` 把数量映射为本地化摘要。普通 Dynamic Type 下，`LibraryEntryDashboard` 用一个 `ViewThatFits(in: .horizontal)` 在“单行三列 `Grid`”与“完整单列 `VStack`”之间整体选择；Accessibility Dynamic Type 直接使用完整单列。`LibraryEntryLayoutPolicy` 为单列卡片返回内容方向，`LibraryEntryCard` 只负责无状态视觉与无障碍呈现，因此候选布局切换不会丢失业务状态。

**Tech Stack:** Swift 6.3、SwiftUI、SwiftData、`LocalizedStringResource`、String Catalog、XCTest、XcodeBuildMCP 2.6.2、iOS 17+。

## Global Constraints

- iOS 最低版本保持 `17.0`，Swift Package 保持 Swift tools `6.3`、Swift language mode 6；不增加第三方依赖。
- 三个入口业务权重相同，只允许“三列”或“单列”两种状态；不得出现两列、`2 + 1`、孤立空位或第三张卡片更宽。
- 响应式选择必须使用当前容器提议的空间，不读取 `UIScreen.main.bounds`，不按设备型号或 `horizontalSizeClass` 分支，也不使用 `.adaptive` `LazyVGrid`。
- 普通 Dynamic Type 由 `ViewThatFits(in: .horizontal)` 根据三列候选的 ideal size 决定：空间足够时外部三列且卡片内部 `.vertical`，空间不足时外部完整单列且卡片内部 `.horizontal`。
- `dynamicTypeSize.isAccessibilitySize == true` 时必须跳过三列候选，外部直接使用完整单列，且卡片内部使用 `.vertical`。
- Accessibility 验收必须确认标题和摘要没有截断，也没有单字或两字宽的极窄文字列。
- 三列卡片最小可读宽度基准为 `104pt`，间距基准为 `12pt`，页面水平边距基准为 `16pt`；这些值使用 `@ScaledMetric(relativeTo: .body)`。页面内容最大宽度固定为 `720pt` 并居中。
- 标签和参与者摘要必须来自实时 SwiftData `@Query` 数量，零值也显示；图表只显示“查看记录趋势”，不得绘制或暗示虚构趋势。
- `LibraryEntryCard` 不访问 SwiftData、不注册导航目标；整张卡片继续使用 typed `NavigationLink(value:)`，不得用 `onTapGesture` 模拟按钮。
- 继续复用唯一的 `.navigationDestination(for: HDiaryDestination.self)`、现有 `HDiaryDestination.libraryEntry(entry:)`、深链处理和资料库导航 store。
- 标题和摘要使用语义字体并允许纵向增长，不用 `.lineLimit(1)`、`.minimumScaleFactor` 或水平 `fixedSize` 强行保留三列；图标和 chevron 不参与 VoiceOver 朗读。
- 本地化只新增 `en` 与 `zh-Hans`，数字和名词必须位于同一个 plural-aware String Catalog 条目中，不做字符串拼接。
- `HDiaryAppFeature` 默认 MainActor 隔离；新增 XCTest 类标注 `@MainActor`，不削弱生产代码隔离。
- 所有 Xcode 构建、测试、运行、截图和 UI 自动化使用 XcodeBuildMCP，不直接调用 `xcodebuild`、`xcrun` 或 `simctl`。
- 真正的 MCP 工具若暴露 `session_show_defaults` / `session_set_defaults`，第一次 build/run/test 前按 `.xcodebuildmcp/config.yaml` 校正默认值；当前 CLI 2.6.2 不暴露这两个命令，因此 CLI 调用必须显式传绝对 `projectPath`、`scheme` 与 `simulatorId`。
- 本地构建和测试不添加代理。只有命令确实需要联网抓取依赖时，才按 `AGENTS.md` 在同一条命令前加完整的 1082 代理环境。
- 若 SwiftPM 报 `fatal: cannot use bare repository ... safe.bareRepository is 'explicit'`，只在失败命令前加 `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all`，不得修改全局 Git 配置。
- 当前工作区已有未跟踪 `.superpowers/` 视觉草图目录；任何任务都不得暂存或提交它。

## 文件结构

- 新建 `HDiaryLibrary/Sources/HDiaryAppFeature/Library/LibraryViewState.swift`：只负责把实时数量映射成三个入口摘要。
- 新建 `HDiaryLibrary/Sources/HDiaryAppFeature/Library/LibraryEntryLayoutPolicy.swift`：负责辅助功能 Dynamic Type 的强制单列规则，并在 Task 5 修订中返回单列卡片的内容方向。
- 新建 `HDiaryLibrary/Sources/HDiaryAppFeature/Library/LibraryEntryDashboard.swift`：只负责三列候选、单列候选和 `ViewThatFits` 的整体选择。
- 新建 `HDiaryLibrary/Sources/HDiaryAppFeature/Library/Entry/LibraryEntryCard.swift`：只负责单张卡片的视觉和无障碍内容。
- 新建 `HDiaryLibrary/Sources/HDiaryAppFeature/Library/Entry/LibraryEntryNavigationCard.swift`：只负责用现有 typed destination 包装整张卡片。
- 修改 `HDiaryLibrary/Sources/HDiaryAppFeature/Library/LibraryView.swift`：查询标签/参与者数量，并用可滚动 Dashboard 替换旧 `List`。
- 修改 `HDiaryLibrary/Sources/HDiaryAppFeature/Common/DiaryStringKey.swift`：提供标签、参与者和图表摘要资源。
- 修改 `HDiary/Localizable.xcstrings`：提供英文复数和简体中文摘要。
- 删除 `HDiaryLibrary/Sources/HDiaryAppFeature/Library/Entry/LibraryEntryCell.swift`：移除不再使用的列表样式。
- 新建 `HDiaryLibrary/Tests/HDiaryAppFeatureTests/LibraryViewStateTests.swift`：覆盖数量映射、零值和图表静态摘要。
- 新建 `HDiaryLibrary/Tests/HDiaryAppFeatureTests/LibraryEntryLayoutPolicyTests.swift`：覆盖普通字号与辅助功能字号规则。
- 新建 `HDiaryLibrary/Tests/HDiaryAppFeatureTests/LibraryEntryRenderingTests.swift`：用 `ImageRenderer` 对卡片两个内容方向和 Dashboard 的关键提议宽度做无崩溃渲染冒烟测试。

---

### Task 1：实时数量摘要与本地化

**Files:**

- Create: `HDiaryLibrary/Sources/HDiaryAppFeature/Library/LibraryViewState.swift`
- Create: `HDiaryLibrary/Tests/HDiaryAppFeatureTests/LibraryViewStateTests.swift`
- Modify: `HDiaryLibrary/Sources/HDiaryAppFeature/Common/DiaryStringKey.swift:190-252`
- Modify: `HDiary/Localizable.xcstrings:1353-1495`

**Interfaces:**

- Consumes: 现有 `LibraryEntry.tag`、`.participant`、`.chart` 和 `DiaryStringKey` 的 App bundle 定位方式。
- Produces: `LibraryViewState.init(tagCount:participantCount:)`、`LibraryViewState.summary(for:) -> LocalizedStringResource`、`DiaryStringKey.tagEntrySummary(count:)`、`participantEntrySummary(count:)`、`chartEntrySummary`。

- [ ] **Step 1：确认 XcodeBuildMCP 执行上下文**

若当前运行时提供原生 MCP session tools，先调用 `session_show_defaults`；缺失或不一致时调用 `session_set_defaults`，参数必须为：

```json
{
  "projectPath": "/Users/tigerguo/.codex/worktrees/81d7/HHappyDocs/HDiary.xcodeproj",
  "scheme": "HDiary",
  "simulatorId": "A044BA15-7770-48E6-8E28-E2123A772ACD",
  "simulatorName": "hdiary 17pro"
}
```

当前 CLI 2.6.2 没有这两个 session 命令，因此使用 CLI 时运行：

```bash
xcodebuildmcp --version
xcodebuildmcp tools
sed -n '1,80p' /Users/tigerguo/.codex/worktrees/81d7/HHappyDocs/.xcodebuildmcp/config.yaml
```

Expected: 版本显示 `2.6.2`；配置显示 `HDiary.xcodeproj`、scheme `HDiary`、模拟器 ID `A044BA15-7770-48E6-8E28-E2123A772ACD`。之后每条 CLI 构建/测试命令继续显式传这些值。

- [ ] **Step 2：先写数量摘要失败测试**

新建 `HDiaryLibrary/Tests/HDiaryAppFeatureTests/LibraryViewStateTests.swift`：

```swift
#if os(iOS)

@testable import HDiaryAppFeature
import XCTest

@MainActor
final class LibraryViewStateTests: XCTestCase {
  func testTagSummaryUsesTagCount() {
    let state = LibraryViewState(tagCount: 3, participantCount: 7)

    XCTAssertEqual(
      state.summary(for: .tag),
      DiaryStringKey.tagEntrySummary(count: 3)
    )
  }

  func testParticipantSummaryUsesParticipantCount() {
    let state = LibraryViewState(tagCount: 3, participantCount: 7)

    XCTAssertEqual(
      state.summary(for: .participant),
      DiaryStringKey.participantEntrySummary(count: 7)
    )
  }

  func testChartSummaryDoesNotDependOnCounts() {
    let emptyState = LibraryViewState(tagCount: 0, participantCount: 0)
    let populatedState = LibraryViewState(tagCount: 12, participantCount: 9)

    XCTAssertEqual(emptyState.summary(for: .chart), DiaryStringKey.chartEntrySummary)
    XCTAssertEqual(populatedState.summary(for: .chart), DiaryStringKey.chartEntrySummary)
  }

  func testZeroCountsRemainVisibleSummaries() {
    let state = LibraryViewState(tagCount: 0, participantCount: 0)

    XCTAssertEqual(
      state.summary(for: .tag),
      DiaryStringKey.tagEntrySummary(count: 0)
    )
    XCTAssertEqual(
      state.summary(for: .participant),
      DiaryStringKey.participantEntrySummary(count: 0)
    )
  }
}

#endif
```

- [ ] **Step 3：运行测试并确认 RED 原因正确**

```bash
xcodebuildmcp simulator test \
  --json '{"projectPath":"/Users/tigerguo/.codex/worktrees/81d7/HHappyDocs/HDiary.xcodeproj","scheme":"HDiary","simulatorId":"A044BA15-7770-48E6-8E28-E2123A772ACD","configuration":"Debug","extraArgs":["-only-testing:HDiaryAppFeatureTests/LibraryViewStateTests"]}' \
  --output text
```

Expected: FAIL；编译器报告找不到 `LibraryViewState`，并报告 `DiaryStringKey` 尚无三个新摘要接口。若失败来自工程路径、模拟器或包缓存，先修复执行环境并重跑，直到 RED 只由缺失功能造成。

- [ ] **Step 4：确认 String Catalog 合同也处于 RED**

```bash
jq -e '
  .strings["library.entry.tag.summary"] != null and
  .strings["library.entry.participant.summary"] != null and
  .strings["library.entry.chart.summary"].localizations.en.stringUnit.value == "View record trends" and
  .strings["library.entry.chart.summary"].localizations["zh-Hans"].stringUnit.value == "查看记录趋势"
' HDiary/Localizable.xcstrings
```

Expected: 退出码 `1`，因为三个条目尚不存在；这证明随后 catalog 改动由明确合同驱动。

- [ ] **Step 5：添加最小字符串接口**

在 `DiaryStringKey.swift` 的 `// MARK: - Library` 区域加入：

```swift
  public static func tagEntrySummary(count: Int) -> LocalizedStringResource {
    LocalizedStringResource(
      "library.entry.tag.summary",
      defaultValue: "\(count) tags",
      bundle: .module,
      comment: "Compact tag count shown on the library entry card"
    )
  }

  public static func participantEntrySummary(count: Int) -> LocalizedStringResource {
    LocalizedStringResource(
      "library.entry.participant.summary",
      defaultValue: "\(count) participants",
      bundle: .module,
      comment: "Compact participant count shown on the library entry card"
    )
  }

  public static let chartEntrySummary = LocalizedStringResource(
    "library.entry.chart.summary",
    defaultValue: "View record trends",
    bundle: .module,
    comment: "Summary shown on the chart library entry card"
  )
```

放置顺序：`tagEntrySummary(count:)` 紧跟 `tagEntryLabel`，`participantEntrySummary(count:)` 紧跟 `participantEntryLabel`，`chartEntrySummary` 紧跟 `chart`。

- [ ] **Step 6：添加英文复数和简体中文 catalog 条目**

在 `HDiary/Localizable.xcstrings` 的 `strings` 对象中按 key 字母顺序加入以下三个完整条目：

```json
    "library.entry.chart.summary" : {
      "comment" : "Summary shown on the chart library entry card",
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "View record trends"
          }
        },
        "zh-Hans" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "查看记录趋势"
          }
        }
      }
    },
    "library.entry.participant.summary" : {
      "comment" : "Compact participant count shown on the library entry card",
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "variations" : {
            "plural" : {
              "one" : {
                "stringUnit" : {
                  "state" : "translated",
                  "value" : "%lld participant"
                }
              },
              "other" : {
                "stringUnit" : {
                  "state" : "translated",
                  "value" : "%lld participants"
                }
              }
            }
          }
        },
        "zh-Hans" : {
          "variations" : {
            "plural" : {
              "other" : {
                "stringUnit" : {
                  "state" : "translated",
                  "value" : "%lld 位参与者"
                }
              }
            }
          }
        }
      }
    },
    "library.entry.tag.summary" : {
      "comment" : "Compact tag count shown on the library entry card",
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "variations" : {
            "plural" : {
              "one" : {
                "stringUnit" : {
                  "state" : "translated",
                  "value" : "%lld tag"
                }
              },
              "other" : {
                "stringUnit" : {
                  "state" : "translated",
                  "value" : "%lld tags"
                }
              }
            }
          }
        },
        "zh-Hans" : {
          "variations" : {
            "plural" : {
              "other" : {
                "stringUnit" : {
                  "state" : "translated",
                  "value" : "%lld 个标签"
                }
              }
            }
          }
        }
      }
    },
```

English 的 `one`/`other` 负责 `1 tag` 与零或复数形式的 `tags`；简体中文统一使用 `other`，零值仍明确显示数字。

- [ ] **Step 7：实现纯值型页面状态**

新建 `HDiaryLibrary/Sources/HDiaryAppFeature/Library/LibraryViewState.swift`：

```swift
#if os(iOS)

import Foundation

struct LibraryViewState {
  let tagCount: Int
  let participantCount: Int

  func summary(for entry: LibraryEntry) -> LocalizedStringResource {
    switch entry {
    case .tag:
      DiaryStringKey.tagEntrySummary(count: tagCount)
    case .participant:
      DiaryStringKey.participantEntrySummary(count: participantCount)
    case .chart:
      DiaryStringKey.chartEntrySummary
    }
  }
}

#endif
```

- [ ] **Step 8：重新运行数量测试并确认 GREEN**

重复 Step 3 的 XcodeBuildMCP 命令。

Expected: `LibraryViewStateTests` 的 4 个测试全部通过，`0 failures`。

- [ ] **Step 9：校验完整 String Catalog**

```bash
jq -e '
  .strings["library.entry.tag.summary"].localizations.en.variations.plural.one.stringUnit.value == "%lld tag" and
  .strings["library.entry.tag.summary"].localizations.en.variations.plural.other.stringUnit.value == "%lld tags" and
  .strings["library.entry.tag.summary"].localizations["zh-Hans"].variations.plural.other.stringUnit.value == "%lld 个标签" and
  .strings["library.entry.participant.summary"].localizations.en.variations.plural.one.stringUnit.value == "%lld participant" and
  .strings["library.entry.participant.summary"].localizations.en.variations.plural.other.stringUnit.value == "%lld participants" and
  .strings["library.entry.participant.summary"].localizations["zh-Hans"].variations.plural.other.stringUnit.value == "%lld 位参与者" and
  .strings["library.entry.chart.summary"].localizations.en.stringUnit.value == "View record trends" and
  .strings["library.entry.chart.summary"].localizations["zh-Hans"].stringUnit.value == "查看记录趋势"
' HDiary/Localizable.xcstrings

jq empty HDiary/Localizable.xcstrings
```

Expected: 两条命令均无输出且退出码为 `0`。

- [ ] **Step 10：提交数量摘要与本地化**

```bash
git add \
  HDiaryLibrary/Sources/HDiaryAppFeature/Library/LibraryViewState.swift \
  HDiaryLibrary/Sources/HDiaryAppFeature/Common/DiaryStringKey.swift \
  HDiaryLibrary/Tests/HDiaryAppFeatureTests/LibraryViewStateTests.swift \
  HDiary/Localizable.xcstrings
git commit -m "Add localized library entry summaries"
```

Expected: commit 成功，且 `git status --short` 仍不会把 `.superpowers/` 纳入 tracked changes。

---

### Task 2：辅助功能字号布局策略

**Files:**

- Create: `HDiaryLibrary/Sources/HDiaryAppFeature/Library/LibraryEntryLayoutPolicy.swift`
- Create: `HDiaryLibrary/Tests/HDiaryAppFeatureTests/LibraryEntryLayoutPolicyTests.swift`

**Interfaces:**

- Consumes: SwiftUI `DynamicTypeSize.isAccessibilitySize`。
- Produces: `LibraryEntryLayoutPolicy.forcesSingleColumn(for:) -> Bool`，供 Dashboard 在构建 `ViewThatFits` 前决定是否直接单列。

- [ ] **Step 1：先写字号策略失败测试**

新建 `HDiaryLibrary/Tests/HDiaryAppFeatureTests/LibraryEntryLayoutPolicyTests.swift`：

```swift
#if os(iOS)

@testable import HDiaryAppFeature
import SwiftUI
import XCTest

@MainActor
final class LibraryEntryLayoutPolicyTests: XCTestCase {
  func testStandardDynamicTypeSizesAllowResponsiveMeasurement() {
    for size in [DynamicTypeSize.xSmall, .large, .xxxLarge] {
      XCTAssertFalse(
        LibraryEntryLayoutPolicy.forcesSingleColumn(for: size),
        "Expected \(size) to let ViewThatFits measure the three-column candidate"
      )
    }
  }

  func testAccessibilityDynamicTypeSizesForceSingleColumn() {
    for size in [DynamicTypeSize.accessibility1, .accessibility3, .accessibility5] {
      XCTAssertTrue(
        LibraryEntryLayoutPolicy.forcesSingleColumn(for: size),
        "Expected \(size) to bypass the three-column candidate"
      )
    }
  }
}

#endif
```

- [ ] **Step 2：运行测试并确认 RED 原因正确**

```bash
xcodebuildmcp simulator test \
  --json '{"projectPath":"/Users/tigerguo/.codex/worktrees/81d7/HHappyDocs/HDiary.xcodeproj","scheme":"HDiary","simulatorId":"A044BA15-7770-48E6-8E28-E2123A772ACD","configuration":"Debug","extraArgs":["-only-testing:HDiaryAppFeatureTests/LibraryEntryLayoutPolicyTests"]}' \
  --output text
```

Expected: FAIL；编译器只因找不到 `LibraryEntryLayoutPolicy` 而失败。

- [ ] **Step 3：添加最小策略实现**

新建 `HDiaryLibrary/Sources/HDiaryAppFeature/Library/LibraryEntryLayoutPolicy.swift`：

```swift
#if os(iOS)

import SwiftUI

enum LibraryEntryLayoutPolicy {
  static func forcesSingleColumn(for dynamicTypeSize: DynamicTypeSize) -> Bool {
    dynamicTypeSize.isAccessibilitySize
  }
}

#endif
```

- [ ] **Step 4：重新运行字号策略测试并确认 GREEN**

重复 Step 2 的 XcodeBuildMCP 命令。

Expected: `LibraryEntryLayoutPolicyTests` 的 2 个测试全部通过，`0 failures`。

- [ ] **Step 5：提交字号策略**

```bash
git add \
  HDiaryLibrary/Sources/HDiaryAppFeature/Library/LibraryEntryLayoutPolicy.swift \
  HDiaryLibrary/Tests/HDiaryAppFeatureTests/LibraryEntryLayoutPolicyTests.swift
git commit -m "Add library entry layout policy"
```

---

### Task 3：无状态入口卡片

**Files:**

- Create: `HDiaryLibrary/Sources/HDiaryAppFeature/Library/Entry/LibraryEntryCard.swift`
- Create: `HDiaryLibrary/Tests/HDiaryAppFeatureTests/LibraryEntryRenderingTests.swift`

**Interfaces:**

- Consumes: 现有 `LibraryEntry.label`、`LibraryEntry.symbol` 和任务 1 的摘要资源。
- Produces: `LibraryEntryCard.init(entry:summary:contentAxis:)`；`.vertical` 用于三列卡片和 Accessibility 单列卡片，`.horizontal` 只用于普通 Dynamic Type 的单列卡片。它不查询数据、不创建 destination。

- [ ] **Step 1：先写两个内容方向的渲染失败测试**

新建 `HDiaryLibrary/Tests/HDiaryAppFeatureTests/LibraryEntryRenderingTests.swift`：

```swift
#if os(iOS)

@testable import HDiaryAppFeature
import SwiftUI
import XCTest

@MainActor
final class LibraryEntryRenderingTests: XCTestCase {
  func testCardRendersForVerticalAndHorizontalContentAxes() {
    let scenarios: [(axis: Axis, width: CGFloat, height: CGFloat)] = [
      (.vertical, 104, 180),
      (.horizontal, 320, 110),
    ]

    for scenario in scenarios {
      let renderer = ImageRenderer(
        content: LibraryEntryCard(
          entry: .tag,
          summary: DiaryStringKey.tagEntrySummary(count: 3),
          contentAxis: scenario.axis
        )
        .frame(width: scenario.width)
      )
      renderer.proposedSize = ProposedViewSize(
        width: scenario.width,
        height: scenario.height
      )

      XCTAssertNotNil(
        renderer.uiImage,
        "Expected the card to render for \(scenario.axis) content"
      )
    }
  }
}

#endif
```

- [ ] **Step 2：运行测试并确认 RED 原因正确**

```bash
xcodebuildmcp simulator test \
  --json '{"projectPath":"/Users/tigerguo/.codex/worktrees/81d7/HHappyDocs/HDiary.xcodeproj","scheme":"HDiary","simulatorId":"A044BA15-7770-48E6-8E28-E2123A772ACD","configuration":"Debug","extraArgs":["-only-testing:HDiaryAppFeatureTests/LibraryEntryRenderingTests"]}' \
  --output text
```

Expected: FAIL；编译器只因找不到 `LibraryEntryCard` 而失败。

- [ ] **Step 3：实现最小卡片视觉和无障碍语义**

新建 `HDiaryLibrary/Sources/HDiaryAppFeature/Library/Entry/LibraryEntryCard.swift`：

```swift
#if os(iOS)

import Foundation
import HDiaryConstants
import SwiftUI

struct LibraryEntryCard: View {
  @ScaledMetric(relativeTo: .body) private var cardPadding: CGFloat = 14
  @ScaledMetric(relativeTo: .body) private var columnSpacing: CGFloat = 8
  @ScaledMetric(relativeTo: .body) private var rowSpacing: CGFloat = 12
  @ScaledMetric(relativeTo: .body) private var cornerRadius: CGFloat = 20
  @ScaledMetric(relativeTo: .body) private var verticalMinimumHeight: CGFloat = 138
  @ScaledMetric(relativeTo: .body) private var horizontalMinimumHeight: CGFloat = 82

  let entry: LibraryEntry
  let summary: LocalizedStringResource
  let contentAxis: Axis

  var body: some View {
    Group {
      if contentAxis == .vertical {
        VStack(alignment: .leading, spacing: columnSpacing) {
          entryIcon
          Text(entry.label)
            .font(.headline)
            .bold()
            .foregroundStyle(.primary)
            .fixedSize(horizontal: false, vertical: true)
          Text(summary)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
          Spacer(minLength: 0)
          HStack {
            Spacer(minLength: 0)
            disclosureIndicator
          }
        }
      }
      else {
        HStack(spacing: rowSpacing) {
          entryIcon
          VStack(alignment: .leading, spacing: columnSpacing / 2) {
            Text(entry.label)
              .font(.headline)
              .bold()
              .foregroundStyle(.primary)
              .fixedSize(horizontal: false, vertical: true)
            Text(summary)
              .font(.subheadline)
              .foregroundStyle(.secondary)
              .fixedSize(horizontal: false, vertical: true)
          }
          .layoutPriority(1)
          Spacer(minLength: 0)
          disclosureIndicator
        }
      }
    }
    .padding(cardPadding)
    .frame(
      maxWidth: .infinity,
      minHeight: minimumHeight,
      maxHeight: .infinity,
      alignment: contentAxis == .vertical ? .topLeading : .leading
    )
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
    .overlay {
      RoundedRectangle(cornerRadius: cornerRadius)
        .stroke(.quaternary, lineWidth: 1)
    }
    .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(entry.label))
    .accessibilityValue(Text(summary))
  }

  private var minimumHeight: CGFloat {
    contentAxis == .vertical ? verticalMinimumHeight : horizontalMinimumHeight
  }

  private var entryIcon: some View {
    Image(hDiarySymbol: entry.symbol)
      .font(.title2)
      .foregroundStyle(Color.accentColor)
      .accessibilityHidden(true)
  }

  private var disclosureIndicator: some View {
    Image(systemName: "chevron.forward")
      .font(.footnote.bold())
      .foregroundStyle(.tertiary)
      .accessibilityHidden(true)
  }
}

#endif
```

背景修饰符必须位于可扩展根 `frame` 之后，以便 `GridRow` 的最高卡片决定行高后，三张卡片的实际背景仍然等高。

- [ ] **Step 4：重新运行卡片渲染测试并确认 GREEN**

重复 Step 2 的 XcodeBuildMCP 命令。

Expected: `testCardRendersForVerticalAndHorizontalContentAxes` 通过，`ImageRenderer` 在两个方向都返回非空 `UIImage`。

- [ ] **Step 5：提交无状态卡片**

```bash
git add \
  HDiaryLibrary/Sources/HDiaryAppFeature/Library/Entry/LibraryEntryCard.swift \
  HDiaryLibrary/Tests/HDiaryAppFeatureTests/LibraryEntryRenderingTests.swift
git commit -m "Add adaptive library entry card"
```

---

### Task 4：Dashboard 响应式布局与 LibraryView 接入

**Files:**

- Create: `HDiaryLibrary/Sources/HDiaryAppFeature/Library/LibraryEntryDashboard.swift`
- Create: `HDiaryLibrary/Sources/HDiaryAppFeature/Library/Entry/LibraryEntryNavigationCard.swift`
- Modify: `HDiaryLibrary/Sources/HDiaryAppFeature/Library/LibraryView.swift:9-53`
- Modify: `HDiaryLibrary/Tests/HDiaryAppFeatureTests/LibraryEntryRenderingTests.swift`
- Delete: `HDiaryLibrary/Sources/HDiaryAppFeature/Library/Entry/LibraryEntryCell.swift`

**Interfaces:**

- Consumes: 任务 1 的 `LibraryViewState`、任务 2 的 `LibraryEntryLayoutPolicy`、任务 3 的 `LibraryEntryCard`、现有 `HDiaryDestination.libraryEntry(entry:)`。
- Produces: `LibraryEntryDashboard.init(viewState:)`；三列候选始终包含一个 `GridRow` 的全部三个入口，回退候选始终包含一个 `VStack` 的全部三个入口。三列卡片内部固定为 `.vertical`；单列卡片最终由 `LibraryEntryLayoutPolicy.singleColumnContentAxis(for:)` 返回内容方向，普通 Dynamic Type 为 `.horizontal`，Accessibility Dynamic Type 为 `.vertical`。

- [ ] **Step 1：先扩展 Dashboard 渲染失败测试**

把 `LibraryEntryRenderingTests.swift` 更新为以下完整内容：

```swift
#if os(iOS)

@testable import HDiaryAppFeature
import SwiftUI
import XCTest

@MainActor
final class LibraryEntryRenderingTests: XCTestCase {
  func testCardRendersForVerticalAndHorizontalContentAxes() {
    let scenarios: [(axis: Axis, width: CGFloat, height: CGFloat)] = [
      (.vertical, 104, 180),
      (.horizontal, 320, 110),
    ]

    for scenario in scenarios {
      let renderer = ImageRenderer(
        content: LibraryEntryCard(
          entry: .tag,
          summary: DiaryStringKey.tagEntrySummary(count: 3),
          contentAxis: scenario.axis
        )
        .frame(width: scenario.width)
      )
      renderer.proposedSize = ProposedViewSize(
        width: scenario.width,
        height: scenario.height
      )

      XCTAssertNotNil(
        renderer.uiImage,
        "Expected the card to render for \(scenario.axis) content"
      )
    }
  }

  func testDashboardRendersForNarrowWideAndAccessibilityProposals() {
    let scenarios: [(width: CGFloat, height: CGFloat, size: DynamicTypeSize)] = [
      (288, 600, .large),
      (360, 300, .large),
      (688, 800, .accessibility3),
    ]

    for scenario in scenarios {
      let renderer = ImageRenderer(
        content: LibraryEntryDashboard(
          viewState: LibraryViewState(tagCount: 3, participantCount: 7)
        )
        .environment(\.dynamicTypeSize, scenario.size)
        .frame(width: scenario.width)
      )
      renderer.proposedSize = ProposedViewSize(
        width: scenario.width,
        height: scenario.height
      )

      XCTAssertNotNil(
        renderer.uiImage,
        "Expected the dashboard to render at width \(scenario.width), size \(scenario.size)"
      )
    }
  }
}

#endif
```

`288pt` 是 `320pt` 窄容器扣除两侧 `16pt` 页面边距后的 Dashboard 宽度；`360pt` 高于三列最低 ideal width `104 × 3 + 12 × 2 = 336pt`；`688pt` 用来证明辅助功能字号即使在宽容器中也能构建单列。Task 4 完成时这个测试只证明外部列数；Task 5 的独立 TDD 修订会进一步锁定普通单列内部 `.horizontal`、Accessibility 单列内部 `.vertical`。

- [ ] **Step 2：运行测试并确认新的 RED 原因正确**

```bash
xcodebuildmcp simulator test \
  --json '{"projectPath":"/Users/tigerguo/.codex/worktrees/81d7/HHappyDocs/HDiary.xcodeproj","scheme":"HDiary","simulatorId":"A044BA15-7770-48E6-8E28-E2123A772ACD","configuration":"Debug","extraArgs":["-only-testing:HDiaryAppFeatureTests/LibraryEntryRenderingTests/testDashboardRendersForNarrowWideAndAccessibilityProposals"]}' \
  --output text
```

Expected: FAIL；编译器只因找不到 `LibraryEntryDashboard` 而失败，任务 3 已存在的卡片测试仍可独立通过。

- [ ] **Step 3：添加 typed NavigationLink 包装器**

新建 `HDiaryLibrary/Sources/HDiaryAppFeature/Library/Entry/LibraryEntryNavigationCard.swift`：

```swift
#if os(iOS)

import Foundation
import SwiftUI

struct LibraryEntryNavigationCard: View {
  let entry: LibraryEntry
  let summary: LocalizedStringResource
  let contentAxis: Axis

  var body: some View {
    NavigationLink(
      value: HDiaryDestination.libraryEntry(entry: entry)
    ) {
      LibraryEntryCard(
        entry: entry,
        summary: summary,
        contentAxis: contentAxis
      )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

#endif
```

不要附加 `.buttonStyle(.plain)`；卡片内部已明确设置语义前景色，保留 `NavigationLink` 的系统按压反馈和导航 trait。

- [ ] **Step 4：实现只有三列与单列两个候选的 Dashboard**

新建 `HDiaryLibrary/Sources/HDiaryAppFeature/Library/LibraryEntryDashboard.swift`：

```swift
#if os(iOS)

import SwiftUI

struct LibraryEntryDashboard: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @ScaledMetric(relativeTo: .body) private var minimumCardWidth: CGFloat = 104
  @ScaledMetric(relativeTo: .body) private var cardSpacing: CGFloat = 12

  let viewState: LibraryViewState

  var body: some View {
    if LibraryEntryLayoutPolicy.forcesSingleColumn(for: dynamicTypeSize) {
      singleColumnLayout
    }
    else {
      ViewThatFits(in: .horizontal) {
        threeColumnLayout
        singleColumnLayout
      }
    }
  }

  private var threeColumnLayout: some View {
    Grid(horizontalSpacing: cardSpacing) {
      GridRow(alignment: .top) {
        ForEach(LibraryEntry.allCases) { entry in
          LibraryEntryNavigationCard(
            entry: entry,
            summary: viewState.summary(for: entry),
            contentAxis: .vertical
          )
          .frame(
            minWidth: minimumCardWidth,
            idealWidth: minimumCardWidth,
            maxWidth: .infinity,
            maxHeight: .infinity
          )
        }
      }
    }
    .frame(maxWidth: .infinity)
  }

  private var singleColumnLayout: some View {
    VStack(spacing: cardSpacing) {
      ForEach(LibraryEntry.allCases) { entry in
        LibraryEntryNavigationCard(
          entry: entry,
          summary: viewState.summary(for: entry),
          contentAxis: .horizontal
        )
      }
    }
    .frame(maxWidth: .infinity)
  }
}

#if DEBUG

#Preview("Three columns") {
  NavigationStack {
    LibraryEntryDashboard(
      viewState: LibraryViewState(tagCount: 3, participantCount: 7)
    )
    .padding(16)
  }
  .frame(width: 390, height: 360)
}

#Preview("Single column - narrow") {
  NavigationStack {
    LibraryEntryDashboard(
      viewState: LibraryViewState(tagCount: 0, participantCount: 0)
    )
    .padding(16)
  }
  .frame(width: 320, height: 600)
}

#Preview("Single column - accessibility") {
  NavigationStack {
    LibraryEntryDashboard(
      viewState: LibraryViewState(tagCount: 12, participantCount: 9)
    )
    .padding(16)
  }
  .environment(\.dynamicTypeSize, .accessibility3)
  .frame(width: 720, height: 800)
}

#endif

#endif
```

> **Task 4 历史基线：** 上述已完成实现把 `singleColumnLayout` 的 `contentAxis` 固定为 `.horizontal`。Task 5 的独立 TDD 修订只会把这一参数改为 `LibraryEntryLayoutPolicy.singleColumnContentAxis(for: dynamicTypeSize)`；三列 `.vertical`、外部 1/3 列选择、导航和数据流均保持不变。

三个 `NavigationLink` 必须作为一个整体放进同一个 `ViewThatFits` 候选，不能让每张卡片分别选择外部列数。`idealWidth` 与 `minWidth` 同时设为可缩放的 `104pt`，让 `ViewThatFits` 按真实三列最低需求做决定。最终内容方向规则是：普通字号三列内部 `.vertical`，普通字号回退单列内部 `.horizontal`，Accessibility 强制单列内部 `.vertical`。

- [ ] **Step 5：用实时 SwiftData 数量接入 LibraryView**

把 `HDiaryLibrary/Sources/HDiaryAppFeature/Library/LibraryView.swift` 更新为：

```swift
//
//  LibraryView.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/18.
//

#if os(iOS)

import HDiaryConstants
import HDiaryModel
import SwiftData
import SwiftUI

@MainActor
struct LibraryView: View {
  private static let maximumContentWidth: CGFloat = 720

  @Environment(HDiaryRoute.self) private var appRoute
  @Query private var tags: [Tag]
  @Query private var participants: [Participant]
  @ScaledMetric(relativeTo: .body) private var contentMargin: CGFloat = 16
  @Binding private var isSelected: Bool

  init(isSelected: Binding<Bool>) {
    self._isSelected = isSelected
  }

  var body: some View {
    @Bindable var appRoute = appRoute
    NavigationStack(path: $appRoute.libraryNavigationStore.path) {
      ScrollView {
        LibraryEntryDashboard(
          viewState: LibraryViewState(
            tagCount: tags.count,
            participantCount: participants.count
          )
        )
        .frame(maxWidth: Self.maximumContentWidth)
        .frame(maxWidth: .infinity)
      }
      .contentMargins(.horizontal, contentMargin, for: .scrollContent)
      .contentMargins(.vertical, contentMargin, for: .scrollContent)
      .navigationDestination(for: HDiaryDestination.self) { destination in
        destination.targetView
      }
      .onOpenURL { url in
        if isSelected {
          Log.Navigation.common.info("handle url in library tab")
          appRoute.libraryNavigationStore.handle(url)
        }
      }
      .navigationTitle(Text(DiaryStringKey.libraryTabItemLabel))
    }
    .environment(appRoute.libraryNavigationStore)
  }
}

#Preview {
  LibraryView(isSelected: .constant(true))
    .previewEnvironment()
}

#endif
```

这一步不得移动、复制或新增 `.navigationDestination(for:)`；它仍然只注册一次。

- [ ] **Step 6：删除旧列表 Cell**

```bash
git rm HDiaryLibrary/Sources/HDiaryAppFeature/Library/Entry/LibraryEntryCell.swift
```

Expected: 文件被标记为删除；`rg -n 'LibraryEntryCell' HDiaryLibrary/Sources HDiaryLibrary/Tests` 无输出。

- [ ] **Step 7：重新运行 Dashboard 渲染测试并确认 GREEN**

```bash
xcodebuildmcp simulator test \
  --json '{"projectPath":"/Users/tigerguo/.codex/worktrees/81d7/HHappyDocs/HDiary.xcodeproj","scheme":"HDiary","simulatorId":"A044BA15-7770-48E6-8E28-E2123A772ACD","configuration":"Debug","extraArgs":["-only-testing:HDiaryAppFeatureTests/LibraryEntryRenderingTests"]}' \
  --output text
```

Expected: `LibraryEntryRenderingTests` 的 2 个测试全部通过；窄宽、足够宽和辅助功能字号三个 Dashboard proposal 均能生成非空图像。

- [ ] **Step 8：运行受影响 target 回归与结构合同检查**

```bash
xcodebuildmcp simulator test \
  --json '{"projectPath":"/Users/tigerguo/.codex/worktrees/81d7/HHappyDocs/HDiary.xcodeproj","scheme":"HDiary","simulatorId":"A044BA15-7770-48E6-8E28-E2123A772ACD","configuration":"Debug","extraArgs":["-only-testing:HDiaryAppFeatureTests"]}' \
  --output text

git diff --check

rg -n 'ViewThatFits|GridRow|@ScaledMetric|isAccessibilitySize|LibraryEntryCard' \
  HDiaryLibrary/Sources/HDiaryAppFeature/Library
```

Expected: 当前基线 15 个 `HDiaryAppFeatureTests` 加本计划新增 8 个测试，共 23 个全部通过；`git diff --check` 无输出；`rg` 命中新的 Dashboard、卡片和布局策略。

然后运行禁用模式检查：

```bash
if rg -n 'UIScreen\.main|horizontalSizeClass|LazyVGrid|GridItem' \
  HDiaryLibrary/Sources/HDiaryAppFeature/Library/LibraryView.swift \
  HDiaryLibrary/Sources/HDiaryAppFeature/Library/LibraryEntryDashboard.swift
then
  exit 1
fi
```

Expected: `rg` 无命中，整个条件命令以 `0` 结束；这两个文件没有设备宽度判断、size class 分支或自适应两列网格。

- [ ] **Step 9：提交 Dashboard 与页面接入**

```bash
git add \
  HDiaryLibrary/Sources/HDiaryAppFeature/Library/LibraryEntryDashboard.swift \
  HDiaryLibrary/Sources/HDiaryAppFeature/Library/Entry/LibraryEntryNavigationCard.swift \
  HDiaryLibrary/Sources/HDiaryAppFeature/Library/LibraryView.swift \
  HDiaryLibrary/Tests/HDiaryAppFeatureTests/LibraryEntryRenderingTests.swift
git add -u HDiaryLibrary/Sources/HDiaryAppFeature/Library/Entry/LibraryEntryCell.swift
git commit -m "Replace library list with adaptive cards"
```

Expected: commit 成功；`.superpowers/` 仍保持未跟踪且未暂存。

---

### Task 5：完整回归、导航和多尺寸视觉验收

**Files:**

- Modify: `HDiaryLibrary/Tests/HDiaryAppFeatureTests/LibraryEntryLayoutPolicyTests.swift`
- Modify: `HDiaryLibrary/Sources/HDiaryAppFeature/Library/LibraryEntryLayoutPolicy.swift`
- Modify: `HDiaryLibrary/Sources/HDiaryAppFeature/Library/LibraryEntryDashboard.swift`
- Verify only: `HDiaryLibrary/Sources/HDiaryAppFeature/Library/**`
- Verify only: `HDiary/Localizable.xcstrings`
- Verify only: `HDiary/HDiary.xctestplan`

**Interfaces:**

- Consumes: Tasks 1–4 的全部实现、`LibraryEntryCard` 已有 vertical/horizontal 分支和 `.xcodebuildmcp/config.yaml`。
- Produces: `LibraryEntryLayoutPolicy.singleColumnContentAxis(for:) -> Axis`、Dashboard 单列内容方向接入、新鲜的 target/full-scheme 测试证据、标准字号和辅助功能字号截图、iPhone/iPad 布局与三个入口导航核对结果。

#### Task 5A：Accessibility 单列卡片内部纵向 TDD 修订（可独立执行）

这一段只修订单列卡片的内部内容方向，不改变外部 1/3 列选择、typed navigation、实时数量、VoiceOver 语义、`720pt` 最大内容宽度或任何 `@ScaledMetric` 数值。

- [ ] **Step A1：先写单列内容方向失败测试**

在现有 `LibraryEntryLayoutPolicyTests` 类中新增以下两个测试；保留 Task 2 已有的强制单列测试：

```swift
  func testStandardDynamicTypeSingleColumnUsesHorizontalContent() {
    XCTAssertEqual(
      LibraryEntryLayoutPolicy.singleColumnContentAxis(for: .large),
      .horizontal
    )
  }

  func testAccessibilityDynamicTypeSingleColumnUsesVerticalContent() {
    XCTAssertEqual(
      LibraryEntryLayoutPolicy.singleColumnContentAxis(for: .accessibility3),
      .vertical
    )
  }
```

第一个测试锁定普通 Dynamic Type 因空间不足回退单列时的 `.horizontal`；第二个测试锁定 Accessibility 强制单列时的 `.vertical`。

- [ ] **Step A2：运行 focused 测试并记录预期 RED**

```bash
xcodebuildmcp simulator test \
  --json '{"projectPath":"/Users/tigerguo/.codex/worktrees/81d7/HHappyDocs/HDiary.xcodeproj","scheme":"HDiary","simulatorId":"A044BA15-7770-48E6-8E28-E2123A772ACD","configuration":"Debug","extraArgs":["-only-testing:HDiaryAppFeatureTests/LibraryEntryLayoutPolicyTests"]}' \
  --output text
```

Expected: FAIL；编译器明确报告 `LibraryEntryLayoutPolicy` 没有 `singleColumnContentAxis(for:)`。如果失败来自工程路径、模拟器或 SwiftPM 缓存，先修复执行环境并重跑，直到 RED 只由缺少新策略接口造成。

- [ ] **Step A3：添加最小策略实现并让 Dashboard 消费结果**

把 `LibraryEntryLayoutPolicy.swift` 更新为：

```swift
#if os(iOS)

import SwiftUI

enum LibraryEntryLayoutPolicy {
  static func forcesSingleColumn(for dynamicTypeSize: DynamicTypeSize) -> Bool {
    dynamicTypeSize.isAccessibilitySize
  }

  static func singleColumnContentAxis(
    for dynamicTypeSize: DynamicTypeSize
  ) -> Axis {
    dynamicTypeSize.isAccessibilitySize ? .vertical : .horizontal
  }
}

#endif
```

然后只把 `LibraryEntryDashboard.singleColumnLayout` 中原有的硬编码 `.horizontal` 替换为策略结果：

```swift
  private var singleColumnLayout: some View {
    VStack(spacing: cardSpacing) {
      ForEach(LibraryEntry.allCases) { entry in
        LibraryEntryNavigationCard(
          entry: entry,
          summary: viewState.summary(for: entry),
          contentAxis: LibraryEntryLayoutPolicy.singleColumnContentAxis(
            for: dynamicTypeSize
          )
        )
      }
    }
    .frame(maxWidth: .infinity)
  }
```

不得修改 `threeColumnLayout` 的 `.vertical`，也不得在 Dashboard 复制 `isAccessibilitySize ? .vertical : .horizontal` 判断；内容方向的唯一策略入口是 `singleColumnContentAxis(for:)`，卡片继续复用现有 vertical 分支。

- [ ] **Step A4：确认 focused GREEN，再运行渲染与 target 回归**

先重复 Step A2 的 focused 命令。

Expected: `LibraryEntryLayoutPolicyTests` 全部通过，新增的两个内容方向测试为 GREEN，`0 failures`。

然后依次运行：

```bash
xcodebuildmcp simulator test \
  --json '{"projectPath":"/Users/tigerguo/.codex/worktrees/81d7/HHappyDocs/HDiary.xcodeproj","scheme":"HDiary","simulatorId":"A044BA15-7770-48E6-8E28-E2123A772ACD","configuration":"Debug","extraArgs":["-only-testing:HDiaryAppFeatureTests/LibraryEntryRenderingTests"]}' \
  --output text

xcodebuildmcp simulator test \
  --json '{"projectPath":"/Users/tigerguo/.codex/worktrees/81d7/HHappyDocs/HDiary.xcodeproj","scheme":"HDiary","simulatorId":"A044BA15-7770-48E6-8E28-E2123A772ACD","configuration":"Debug","extraArgs":["-only-testing:HDiaryAppFeatureTests"]}' \
  --output text
```

Expected: `LibraryEntryRenderingTests` 和整个 `HDiaryAppFeatureTests` target 均为 `0 failures`。记录本次实际执行数量，不复用计划中的历史测试数。

- [ ] **Step A5：更新 Preview 与模拟器验收期望**

复核现有三个 Preview，不新增另一套布局实现：

- `Three columns`：普通 Dynamic Type、空间足够，外部三列，每张卡片内部 vertical。
- `Single column - narrow`：普通 Dynamic Type、空间不足，外部完整单列，每张卡片内部 horizontal。
- `Single column - accessibility`：`.accessibility3`，外部完整单列，每张卡片内部 vertical。

随后执行下方 Task 5B Step 8 的英文 Accessibility 模拟器命令并保存 snapshot/截图。验收时必须同时确认：标题和摘要没有截断；`Tag`、`20 tags` 等内容没有被挤成单字或两字宽的极窄文字列；三张卡片外部仍是完整单列且等宽。普通窄屏单列则在 `Single column - narrow` Preview 中确认内部仍为 horizontal。

- [ ] **Step A6：提交最小生产修订与测试**

```bash
git diff --check
git add \
  HDiaryLibrary/Sources/HDiaryAppFeature/Library/LibraryEntryLayoutPolicy.swift \
  HDiaryLibrary/Sources/HDiaryAppFeature/Library/LibraryEntryDashboard.swift \
  HDiaryLibrary/Tests/HDiaryAppFeatureTests/LibraryEntryLayoutPolicyTests.swift
git commit -m "Use vertical accessibility library cards"
```

Expected: commit 成功；`.superpowers/` 没有被暂存或提交。

#### Task 5B：完整回归、导航与多尺寸视觉终检

- [ ] **Step 1：运行 catalog、diff 和静态结构终检**

```bash
jq empty HDiary/Localizable.xcstrings
git diff --check "$(git merge-base HEAD origin/main)"..HEAD
git status --short
```

Expected: catalog 是有效 JSON；diff 无空白错误；status 只允许显示执行前已有的 `?? .superpowers/`，不应有遗漏的 tracked 改动。

```bash
rg -n 'ViewThatFits\(in: \.horizontal\)|GridRow|minimumCardWidth|maximumContentWidth|isAccessibilitySize|singleColumnContentAxis' \
  HDiaryLibrary/Sources/HDiaryAppFeature/Library
```

Expected: 能明确看到一个水平 `ViewThatFits`、一个单行 `GridRow`、可缩放最小宽度、`720pt` 最大宽度、辅助功能字号短路规则和唯一的单列内容方向策略接口。

- [ ] **Step 2：运行 HDiaryAppFeature 定向回归**

```bash
xcodebuildmcp simulator test \
  --json '{"projectPath":"/Users/tigerguo/.codex/worktrees/81d7/HHappyDocs/HDiary.xcodeproj","scheme":"HDiary","simulatorId":"A044BA15-7770-48E6-8E28-E2123A772ACD","configuration":"Debug","extraArgs":["-only-testing:HDiaryAppFeatureTests"]}' \
  --output text
```

Expected: Task 5A 新增的两个策略测试与既有 target 测试全部通过、`0 failures`。必须记录本次实际执行数量，不得复用历史数量。

- [ ] **Step 3：运行默认 test plan 完整回归**

```bash
xcodebuildmcp simulator test \
  --project-path /Users/tigerguo/.codex/worktrees/81d7/HHappyDocs/HDiary.xcodeproj \
  --scheme HDiary \
  --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD \
  --configuration Debug \
  --output text
```

Expected: 默认 test plan 中既有测试与 Task 5A 新增的两个策略测试全部通过、`0 failures`。默认计划仍不包含 3 个既有 `HDiaryUITests`；若原始 discovery 数比执行数多 3，不得误报为回归，也不得声称 UI tests 已执行。以本次实际输出记录最终测试数。

- [ ] **Step 4：在 iPhone 标准字号、简体中文环境构建并运行**

```bash
xcodebuildmcp simulator build-and-run \
  --json '{"projectPath":"/Users/tigerguo/.codex/worktrees/81d7/HHappyDocs/HDiary.xcodeproj","scheme":"HDiary","simulatorId":"A044BA15-7770-48E6-8E28-E2123A772ACD","configuration":"Debug","launchArgs":["-AppleLanguages","(zh-Hans)","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryL"]}' \
  --output text
```

Expected: App 安装并启动成功；日志没有 SwiftUI runtime warning 或崩溃。

- [ ] **Step 5：进入资料库并保存标准字号证据**

```bash
xcodebuildmcp ui-automation wait-for-ui \
  --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD \
  --predicate exists \
  --label '资料库' \
  --role tab \
  --timeout-ms 10000 \
  --output text
```

从这条命令返回的最新 snapshot 中读取“资料库”tab 的真实 `elementRef`，立即调用 `xcodebuildmcp ui-automation tap`；`elementRef` 是运行时值，必须使用实际输出，不得猜测或写死。导航后运行：

```bash
xcodebuildmcp ui-automation wait-for-ui \
  --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD \
  --predicate textContains \
  --text '查看记录趋势' \
  --timeout-ms 10000 \
  --output text

xcodebuildmcp ui-automation snapshot-ui \
  --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD \
  --output text

xcodebuildmcp simulator screenshot \
  --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD \
  --return-format path \
  --output text
```

Expected: snapshot 中只有标签、参与者、图表三个平级入口；标准字号且空间足够时外部三列、每张卡片内部 vertical，三者 frame 的纵坐标、宽度和高度一致，没有横向滚动、两列或 `2 + 1`；VoiceOver 节点顺序是标签、参与者、图表，每个节点同时包含标题与摘要。

- [ ] **Step 6：逐一验证三个现有导航目标和实时计数**

依次从最新 snapshot 取得“标签”“参与者”“图表”的可点击 `elementRef`，每次只调用一次 `ui-automation tap`。每次导航后刷新 `snapshot-ui`，确认分别出现现有标签列表、参与者列表、图表入口页；再使用刷新后 snapshot 中系统返回按钮的真实 `elementRef` 返回资料库。

在标签页新增一条标签后返回资料库，确认标签摘要增加 1；删除该标签并返回，确认摘要恢复。参与者执行同样的新增/删除往返检查。图表摘要始终保持“查看记录趋势”，且不出现迷你趋势图。

Expected: 三个 typed destination 都保持原行为；`@Query` 变化无需重新启动页面即可刷新摘要；零值状态仍显示 `0 个标签` 或 `0 位参与者`。

- [ ] **Step 7：验证浅色、深色与提高对比度可读性**

```bash
xcodebuildmcp simulator-management set-appearance \
  --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD \
  --mode light \
  --output text

xcodebuildmcp simulator screenshot \
  --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD \
  --return-format path \
  --output text

xcodebuildmcp simulator-management set-appearance \
  --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD \
  --mode dark \
  --output text

xcodebuildmcp simulator screenshot \
  --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD \
  --return-format path \
  --output text
```

Expected: 两种外观下 material 卡片边界、主文字、次要摘要、橙色图标和 chevron 均清晰。再在 Simulator Settings 开启 Increase Contrast，并用相同的 XcodeBuildMCP screenshot 命令取证；不能只凭构建成功声称高对比度通过。

- [ ] **Step 8：验证英文辅助功能字号强制单列**

```bash
xcodebuildmcp simulator stop \
  --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD \
  --bundle-id com.tiger.suzhou.HDiary-Debug \
  --output text

xcodebuildmcp simulator launch-app \
  --json '{"simulatorId":"A044BA15-7770-48E6-8E28-E2123A772ACD","bundleId":"com.tiger.suzhou.HDiary-Debug","launchArgs":["-AppleLanguages","(en)","-AppleLocale","en_US","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"]}' \
  --output text
```

再次通过真实 snapshot ref 点击 Library tab，然后运行：

```bash
xcodebuildmcp ui-automation wait-for-ui \
  --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD \
  --predicate textContains \
  --text 'View record trends' \
  --timeout-ms 10000 \
  --output text

xcodebuildmcp ui-automation snapshot-ui \
  --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD \
  --output text

xcodebuildmcp simulator screenshot \
  --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD \
  --return-format path \
  --output text
```

Expected: 外部为三张等宽的完整单列卡片，每张卡片内部为 vertical；标题与英文单复数摘要完整可读、没有截断，也没有 `Tag`、`20 tags` 等内容被挤成单字或两字宽的极窄文字列。必须从 snapshot 的文字 frame 确认字号确实增大；若该 runtime 忽略启动覆盖，则在 Simulator Settings 手动选择最大 Larger Text 后重取 snapshot/截图，不能把 launch 命令成功当作 Dynamic Type 已验证。

- [ ] **Step 9：验证 iPad 宽屏最大宽度和三列一致性**

使用本机现有 `iPad Pro 13-inch (M5)` 模拟器：

```bash
xcodebuildmcp simulator build-and-run \
  --json '{"projectPath":"/Users/tigerguo/.codex/worktrees/81d7/HHappyDocs/HDiary.xcodeproj","scheme":"HDiary","simulatorId":"2D15C1CC-968A-4A02-B13A-20166E188204","configuration":"Debug","launchArgs":["-AppleLanguages","(zh-Hans)","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryL"]}' \
  --output text
```

通过该模拟器 snapshot 返回的真实 ref 点击资料库 tab，再运行：

```bash
xcodebuildmcp ui-automation snapshot-ui \
  --simulator-id 2D15C1CC-968A-4A02-B13A-20166E188204 \
  --output text

xcodebuildmcp simulator screenshot \
  --simulator-id 2D15C1CC-968A-4A02-B13A-20166E188204 \
  --return-format path \
  --output text
```

Expected: 卡片内容区域居中且总宽度不超过 `720pt`；外部仍为三张同排、同宽、同高卡片，每张内部为 vertical，不会因 iPad 更宽而拉伸到整个屏幕。

- [ ] **Step 10：复核窄宽 Preview 与最终 Git 状态**

在 Xcode Preview 中依次核对 `LibraryEntryDashboard.swift` 的 `Three columns`、`Single column - narrow`、`Single column - accessibility` 三个 Preview：

- `390pt` 标准字号：外部三列，每张卡片内部 vertical。
- `320pt` 标准字号（Dashboard 可用宽度约 `288pt`）：外部完整单列，每张卡片内部 horizontal。
- `720pt` `.accessibility3`：外部完整单列，每张卡片内部 vertical。

Expected: 任意 Preview 都只有 1 或 3 列；没有标题或摘要截断、水平滚动、两列和 `2 + 1`。Accessibility Preview 还不得出现单字或两字宽的极窄文字列。若当前环境通过 XcodeBuildMCP 的 `xcode-ide` workflow 连接到 Xcode，先运行 `xcodebuildmcp xcode-ide bridge-status --output text` 与 `xcodebuildmcp xcode-ide list-tools --refresh --output text`，再使用该连接实际返回的 Preview render tool 取图；工具名和参数必须来自该次 `list-tools` 输出，不得臆造。

最后运行：

```bash
git status --short
git log -5 --oneline
```

Expected: Tasks 1–4 的实现 commit、Task 5A 的 Accessibility 内容方向修订 commit 都存在；没有未提交的 tracked 文件；仅保留执行前已有的 `?? .superpowers/`。把测试数量、三种关键布局截图路径、三条导航结果和任何未能自动化的手工核对项写入交付说明。
