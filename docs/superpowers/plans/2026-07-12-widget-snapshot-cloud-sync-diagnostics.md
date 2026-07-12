# Widget 独立快照与 CloudKit 同步诊断实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让 Widget 完全脱离主 CloudKit Store，改读独立、有界、只读的 snapshot Store，并在 TestFlight/正式版提供可导出的 CloudKit 同步诊断。

**Architecture:** 新增不依赖主业务模型的 `HDiaryWidgetData` target，主 App 将必要的 Participant 和 Moment 摘要投影到独立 App Group Store，Widget 仅以 `allowsSave: false` 读取。主 App 在主容器创建前监听 CloudKit event，使用 actor 将最近 100 条脱敏事件原子写入 JSON；同一个远端变化观察器触发 snapshot 重建与 Widget timeline 刷新。

**Tech Stack:** Swift 6.3、SwiftData、Swift Concurrency、Combine、Core Data notifications、CloudKit、WidgetKit、SwiftUI、XCTest、XcodeBuildMCP CLI 2.6.2。

## Global Constraints

- 保持 `HDiaryLibrary/Package.swift` 的 `.iOS(.v17)`、`.macOS(.v14)`、Swift 6 language mode、Strict Concurrency。
- 新增 `HDiaryAppFeature`、`HDiaryWidgetIntents`、`HDiaryWidgetFeature` 和对应测试源码沿用 `#if os(iOS)`；纯 `HDiaryWidgetData` target 同时编译 iOS 17 与 macOS 14。
- 不添加第三方依赖，不修改主 CloudKit container identifier 或生产 schema。
- Widget 不得导入 `HDiaryModel`、不得打开主 Store、不得持有 CloudKit entitlement。
- Snapshot Store 固定使用不同 URL、`cloudKitDatabase: .none`；reader 为 `allowsSave: false`，writer 为 `allowsSave: true`。
- Snapshot 保存全部 Participant，但只保存全局最近 8 条与每位 Participant 最近 8 条 Moment 的去重并集。
- Snapshot 不保存正文、媒体、标签、评分或原始头像；头像缩略图最长边固定为 64 px。
- CloudKit 诊断文件名固定为 `cloud-sync-events.json`，最多保留最近 100 个 event identifier。
- 诊断文件不记录日记内容、CloudKit record 内容或用户标识，并排除设备备份。
- 先写失败测试并观察预期失败，再写最小实现；每个任务单独提交。
- 所有构建、测试、运行和模拟器操作使用 `xcodebuildmcp`，不直接调用 `xcodebuild`、`xcrun` 或 `simctl`。
- 当前 CLI 2.6.2 不提供 `session_show_defaults`/`session_set_defaults`；每次调用显式传入 `.xcodebuildmcp/config.yaml` 中的绝对 project path、scheme 和 simulator ID：`/Users/tigerguo/.codex/worktrees/76f2/HHappyDocs/HDiary.xcodeproj`、`HDiary`、`A044BA15-7770-48E6-8E28-E2123A772ACD`。
- 如果 SwiftPM bare repository cache 报 `safe.bareRepository is 'explicit'`，仅在失败命令前加 `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all`，不修改全局 Git 配置。

---

## 文件结构

### 新增 `HDiaryWidgetData` target

- `HDiaryLibrary/Sources/HDiaryWidgetData/Model/WidgetParticipantSnapshot.swift`：Participant 轻量 SwiftData model。
- `HDiaryLibrary/Sources/HDiaryWidgetData/Model/WidgetMomentSnapshot.swift`：Moment 轻量 SwiftData model。
- `HDiaryLibrary/Sources/HDiaryWidgetData/Model/WidgetSnapshotValue.swift`：跨 actor 传递的 Sendable 值。
- `HDiaryLibrary/Sources/HDiaryWidgetData/Storage/WidgetSnapshotContainer.swift`：独立 Store URL、reader/writer configuration 和容器创建。
- `HDiaryLibrary/Sources/HDiaryWidgetData/Storage/WidgetSnapshotStore.swift`：actor 隔离的原子 replace/read。
- `HDiaryLibrary/Tests/HDiaryWidgetDataTests/WidgetSnapshotContainerTests.swift`：配置测试。
- `HDiaryLibrary/Tests/HDiaryWidgetDataTests/WidgetSnapshotStoreTests.swift`：存储替换测试。

### 新增主 App snapshot 流程

- `HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/WidgetSnapshotSource.swift`：从主模型复制出的 Sendable source values。
- `HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/WidgetAvatarThumbnailer.swift`：64 px 头像缩略。
- `HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/WidgetSnapshotProjector.swift`：有界集合投影。
- `HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/MainStoreWidgetSnapshotBuilder.swift`：只在主 actor 读取主 SwiftData Store。
- `HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/WidgetSnapshotCoordinator.swift`：debounce、串行重建、成功后刷新 timeline。
- `HDiaryLibrary/Tests/HDiaryAppFeatureTests/WidgetSnapshotProjectorTests.swift`：投影边界测试。
- `HDiaryLibrary/Tests/HDiaryAppFeatureTests/WidgetSnapshotCoordinatorTests.swift`：触发、合并和失败测试。

### 新增同步诊断

- `HDiaryLibrary/Sources/HDiaryAppFeature/CloudSyncDiagnostics/CloudSyncEventRecord.swift`：Codable/Sendable 诊断值。
- `HDiaryLibrary/Sources/HDiaryAppFeature/CloudSyncDiagnostics/CloudSyncErrorDetails.swift`：错误链与 retry-after 解析。
- `HDiaryLibrary/Sources/HDiaryAppFeature/CloudSyncDiagnostics/CloudSyncDiagnosticsFileStore.swift`：actor 隔离的有界 JSON 文件。
- `HDiaryLibrary/Sources/HDiaryAppFeature/CloudSyncDiagnostics/CloudSyncDiagnosticsModel.swift`：SwiftUI 可观察状态。
- `HDiaryLibrary/Sources/HDiaryAppFeature/CloudSyncDiagnostics/CloudSyncMonitor.swift`：CloudKit event、remote change 和 local save 观察。
- `HDiaryLibrary/Sources/HDiaryAppFeature/CloudSyncDiagnostics/CloudSyncRuntime.swift`：保证观察器先于主容器初始化并连接 snapshot coordinator。
- `HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Data/CloudData/Diagnostics/CloudSyncDiagnosticsScreen.swift`：诊断列表和分享入口。
- `HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Data/CloudData/Diagnostics/CloudSyncEventRow.swift`：单条事件展示。
- `HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Data/CloudData/Diagnostics/CloudSyncDiagnosticsEmptyView.swift`：无事件状态。
- `HDiaryLibrary/Tests/HDiaryAppFeatureTests/CloudSyncDiagnosticsTests.swift`：映射、错误解析、文件持久化测试。
- `HDiaryLibrary/Tests/HDiaryAppFeatureTests/CloudSyncMonitorTests.swift`：通知过滤与运行时幂等测试。

### 修改现有文件

- `HDiaryLibrary/Package.swift`：增加 product/targets，调整 Widget target 依赖。
- `HDiary.xctestplan`：纳入 `HDiaryWidgetDataTests`。
- `HDiaryLibrary/Sources/HDiaryModel/Model/Container/ModelContainer.swift`：公开稳定的主 Store configuration/URL，容器仍只在主 App 使用。
- `HDiaryLibrary/Sources/HDiaryWidgetIntents/MomentWidget/MomentWidgetUtil.swift`：改成 snapshot data source。
- `HDiaryLibrary/Sources/HDiaryWidgetIntents/MomentWidget/MomentWidgetIntent.swift`：Participant options 改读 snapshot。
- `HDiaryLibrary/Sources/HDiaryWidgetFeature/MomentWidget/MomentTimeLineProvider.swift`：timeline 改读 snapshot。
- `HDiaryLibrary/Tests/HDiaryAppFeatureTests/MomentWidgetIntentTests.swift`：改为独立 Store 读取测试。
- `HDiaryLibrary/Sources/HDiaryAppFeature/HDiaryApp.swift`：启动 CloudSync runtime。
- `HDiaryLibrary/Sources/HDiaryAppFeature/Common/Navigation/HDiaryNavigatorModifier.swift`：增加诊断 destination。
- `HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Data/CloudData/Entry/CloudDataEntryScreen.swift`：增加正式可见的诊断入口。
- `HDiaryLibrary/Sources/HDiaryAppFeature/Common/DiaryStringKey.swift`、`HDiary/Localizable.xcstrings`：英中诊断文案。
- `HDiaryWidgetExtension.entitlements`、`HDiaryWidgetExtensionDebug.entitlements`：删除 iCloud/CloudKit keys，保留 App Group。

---

### Task 0: 固定基线与 XcodeBuildMCP 上下文

**Files:**
- Verify: `.xcodebuildmcp/config.yaml`
- Verify: current worktree and baseline tests。

**Interfaces:**
- Produces: 后续所有 RED/GREEN 结果可比较的基线证据。

- [ ] **Step 1: 显示项目 defaults 和 CLI 能力**

```bash
sed -n '1,120p' .xcodebuildmcp/config.yaml
xcodebuildmcp --version
xcodebuildmcp tools | rg "session_(show|set)_defaults" || true
```

Expected: config 显示 `HDiary.xcodeproj`、`HDiary`、
`A044BA15-7770-48E6-8E28-E2123A772ACD`；CLI 为 2.6.2；最后一条无输出，确认必须显式传参。

- [ ] **Step 2: 记录干净工作区和基线测试**

```bash
git status --short --branch
xcodebuildmcp simulator test --project-path /Users/tigerguo/.codex/worktrees/76f2/HHappyDocs/HDiary.xcodeproj --scheme HDiary --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD
```

Expected: 除本计划提交外工作区无未提交变更；现有 HDiary test plan 为 0 failures。若这里失败，
先按 `systematic-debugging` 判断是否为基线问题，不能把既有失败归因于 snapshot 实现。

---

### Task 1: 建立独立 snapshot schema 与容器配置

**Files:**
- Create: `HDiaryLibrary/Sources/HDiaryWidgetData/HDiaryWidgetData.swift`
- Create: `HDiaryLibrary/Sources/HDiaryWidgetData/Model/WidgetParticipantSnapshot.swift`
- Create: `HDiaryLibrary/Sources/HDiaryWidgetData/Model/WidgetMomentSnapshot.swift`
- Create: `HDiaryLibrary/Sources/HDiaryWidgetData/Model/WidgetSnapshotValue.swift`
- Create: `HDiaryLibrary/Sources/HDiaryWidgetData/Storage/WidgetSnapshotContainer.swift`
- Create: `HDiaryLibrary/Tests/HDiaryWidgetDataTests/WidgetSnapshotContainerTests.swift`
- Modify: `HDiaryLibrary/Package.swift`
- Modify: `HDiary.xctestplan`

**Interfaces:**
- Produces: `WidgetParticipantSnapshot`, `WidgetMomentSnapshot`。
- Produces: `WidgetSnapshotValue(participants:moments:)`、`WidgetParticipantValue`、`WidgetMomentValue`，全部 `Sendable & Equatable`。
- Produces: `WidgetSnapshotContainer.storeURL`、`configuration(url:allowsSave:)`、`makeWriterContainer(at:)`、`makeReaderContainer(at:)`。

- [ ] **Step 1: 先添加 target scaffolding 和失败配置测试**

在 `Package.swift` 增加空的 `HDiaryWidgetData` product/target/test target，并把测试 target 加入 `HDiary.xctestplan`。`HDiaryWidgetData.swift` 只放模块注释，不定义目标 API。测试写成：

```swift
import SwiftData
@testable import HDiaryWidgetData
import XCTest

final class WidgetSnapshotContainerTests: XCTestCase {
  func testReaderAndWriterUseDedicatedNonCloudStore() {
    let url = FileManager.default.temporaryDirectory
      .appending(path: UUID().uuidString)
      .appending(path: "widget-snapshot.sqlite")

    let writer = WidgetSnapshotContainer.configuration(url: url, allowsSave: true)
    let reader = WidgetSnapshotContainer.configuration(url: url, allowsSave: false)

    XCTAssertEqual(writer.url, url)
    XCTAssertEqual(reader.url, url)
    XCTAssertTrue(writer.allowsSave)
    XCTAssertFalse(reader.allowsSave)
    XCTAssertNil(writer.cloudKitContainerIdentifier)
    XCTAssertNil(reader.cloudKitContainerIdentifier)
  }

  func testSnapshotValuesContainOnlyWidgetFields() {
    let participant = WidgetParticipantValue(
      uuid: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
      nickName: "Tiger",
      avatarThumbnailData: Data([1, 2, 3])
    )
    let moment = WidgetMomentValue(
      uuid: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
      timestamp: Date(timeIntervalSince1970: 100),
      title: "Moment",
      participantIDs: [participant.uuid]
    )

    XCTAssertEqual(WidgetSnapshotValue(participants: [participant], moments: [moment]).moments, [moment])
  }
}
```

- [ ] **Step 2: 运行测试并确认因 API 尚不存在而失败**

Run:

```bash
xcodebuildmcp simulator test --project-path /Users/tigerguo/.codex/worktrees/76f2/HHappyDocs/HDiary.xcodeproj --scheme HDiary --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD --extra-args "-only-testing:HDiaryWidgetDataTests/WidgetSnapshotContainerTests"
```

Expected: FAIL，错误包含 `cannot find 'WidgetSnapshotContainer' in scope` 或 `cannot find 'WidgetParticipantValue' in scope`。

- [ ] **Step 3: 实现轻量模型和值类型**

`WidgetParticipantSnapshot.swift`：

```swift
import Foundation
import SwiftData

@Model
public final class WidgetParticipantSnapshot {
  @Attribute(.unique) public var uuid: UUID = UUID()
  public var nickName: String = ""
  public var avatarThumbnailData: Data?

  public init(uuid: UUID, nickName: String, avatarThumbnailData: Data?) {
    self.uuid = uuid
    self.nickName = nickName
    self.avatarThumbnailData = avatarThumbnailData
  }
}
```

`WidgetMomentSnapshot.swift`：

```swift
import Foundation
import SwiftData

@Model
public final class WidgetMomentSnapshot {
  @Attribute(.unique) public var uuid: UUID = UUID()
  public var timestamp: Date = .distantPast
  public var title: String = ""
  public var participantIDs: [UUID] = []

  public init(uuid: UUID, timestamp: Date, title: String, participantIDs: [UUID]) {
    self.uuid = uuid
    self.timestamp = timestamp
    self.title = title
    self.participantIDs = participantIDs
  }
}
```

`WidgetSnapshotValue.swift` 定义三个 public value type；数组在 initializer 中按 UUID 和时间保持调用方提供的顺序，不引入业务字段：

```swift
import Foundation

public struct WidgetParticipantValue: Sendable, Equatable {
  public let uuid: UUID
  public let nickName: String
  public let avatarThumbnailData: Data?

  public init(uuid: UUID, nickName: String, avatarThumbnailData: Data?) {
    self.uuid = uuid
    self.nickName = nickName
    self.avatarThumbnailData = avatarThumbnailData
  }
}

public struct WidgetMomentValue: Sendable, Equatable {
  public let uuid: UUID
  public let timestamp: Date
  public let title: String
  public let participantIDs: [UUID]

  public init(uuid: UUID, timestamp: Date, title: String, participantIDs: [UUID]) {
    self.uuid = uuid
    self.timestamp = timestamp
    self.title = title
    self.participantIDs = participantIDs
  }
}

public struct WidgetSnapshotValue: Sendable, Equatable {
  public let participants: [WidgetParticipantValue]
  public let moments: [WidgetMomentValue]

  public init(participants: [WidgetParticipantValue], moments: [WidgetMomentValue]) {
    self.participants = participants
    self.moments = moments
  }
}
```

- [ ] **Step 4: 实现明确 URL 的 reader/writer 配置**

`WidgetSnapshotContainer.swift` 使用 `Schema([WidgetParticipantSnapshot.self, WidgetMomentSnapshot.self])`。默认 URL 必须为：

```swift
AppConstants.groupContainerURL
  .appending(components: "Library", "Application Support", "WidgetSnapshot", "widget-snapshot.sqlite")
```

核心接口：

```swift
public enum WidgetSnapshotContainer {
  public static let schema = Schema([WidgetParticipantSnapshot.self, WidgetMomentSnapshot.self])

  public static var storeURL: URL { /* 上述固定 URL */ }

  public static func configuration(url: URL, allowsSave: Bool) -> ModelConfiguration {
    ModelConfiguration(
      "WidgetSnapshot",
      schema: schema,
      url: url,
      allowsSave: allowsSave,
      cloudKitDatabase: .none
    )
  }

  public static func makeWriterContainer(at url: URL = storeURL) throws -> ModelContainer {
    try prepareStoreDirectory(for: url)
    return try ModelContainer(for: schema, configurations: [configuration(url: url, allowsSave: true)])
  }

  public static func makeReaderContainer(at url: URL = storeURL) throws -> ModelContainer {
    try ModelContainer(for: schema, configurations: [configuration(url: url, allowsSave: false)])
  }
}
```

`prepareStoreDirectory(for:)` 创建父目录，将目录的 `isExcludedFromBackup` 设为 `true`；不在 reader 路径创建空 Store。

- [ ] **Step 5: 运行配置测试并确认通过**

Run: 与 Step 2 相同。

Expected: PASS，`WidgetSnapshotContainerTests` 2/2 通过。

- [ ] **Step 6: 提交 Task 1**

```bash
git add HDiaryLibrary/Package.swift HDiary.xctestplan HDiaryLibrary/Sources/HDiaryWidgetData HDiaryLibrary/Tests/HDiaryWidgetDataTests/WidgetSnapshotContainerTests.swift
git commit -m "Add dedicated widget snapshot schema"
```

---

### Task 2: 实现 snapshot Store 的全量替换事务

**Files:**
- Create: `HDiaryLibrary/Sources/HDiaryWidgetData/Storage/WidgetSnapshotStore.swift`
- Create: `HDiaryLibrary/Tests/HDiaryWidgetDataTests/WidgetSnapshotStoreTests.swift`

**Interfaces:**
- Consumes: `WidgetSnapshotValue`、`WidgetSnapshotContainer`。
- Produces: `public actor WidgetSnapshotStore`。
- Produces: `replace(with:) async throws` 和 `snapshot() async throws -> WidgetSnapshotValue`。

- [ ] **Step 1: 写入替换、更新、清理和只读失败测试**

测试使用每个 test 独立的临时目录：

```swift
final class WidgetSnapshotStoreTests: XCTestCase {
  func testReplaceUpdatesExistingRowsAndDeletesStaleRows() async throws {
    let url = temporaryStoreURL()
    let container = try WidgetSnapshotContainer.makeWriterContainer(at: url)
    let store = WidgetSnapshotStore(modelContainer: container)

    let first = WidgetSnapshotValue(
      participants: [participant(id: 1, name: "Old"), participant(id: 2, name: "Stale")],
      moments: [moment(id: 1, title: "Old"), moment(id: 2, title: "Stale")]
    )
    let second = WidgetSnapshotValue(
      participants: [participant(id: 1, name: "New")],
      moments: [moment(id: 1, title: "New")]
    )

    try await store.replace(with: first)
    try await store.replace(with: second)

    let persisted = try await store.snapshot()
    XCTAssertEqual(persisted, second)
  }

  @MainActor
  func testReaderContainerReadsWriterDataAndRejectsSave() async throws {
    let url = temporaryStoreURL()
    let writerContainer = try WidgetSnapshotContainer.makeWriterContainer(at: url)
    let store = WidgetSnapshotStore(modelContainer: writerContainer)
    try await store.replace(with: .init(participants: [participant(id: 1, name: "Tiger")], moments: []))

    let readerContainer = try WidgetSnapshotContainer.makeReaderContainer(at: url)
    let context = ModelContext(readerContainer)
    XCTAssertEqual(try context.fetch(FetchDescriptor<WidgetParticipantSnapshot>()).map(\.nickName), ["Tiger"])

    context.insert(WidgetParticipantSnapshot(uuid: UUID(), nickName: "Forbidden", avatarThumbnailData: nil))
    XCTAssertThrowsError(try context.save())
  }
}
```

测试 helper 使用以下完整实现，确保 UUID 和排序稳定，并在 teardown 删除目录：

```swift
private func fixedUUID(_ value: Int) -> UUID {
  UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", value))!
}

private func participant(id: Int, name: String) -> WidgetParticipantValue {
  WidgetParticipantValue(uuid: fixedUUID(id), nickName: name, avatarThumbnailData: nil)
}

private func moment(id: Int, title: String) -> WidgetMomentValue {
  WidgetMomentValue(
    uuid: fixedUUID(1_000 + id),
    timestamp: Date(timeIntervalSince1970: TimeInterval(id)),
    title: title,
    participantIDs: [fixedUUID(1)]
  )
}

private func temporaryStoreURL() -> URL {
  let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
  addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
  return directory.appending(path: "widget-snapshot.sqlite")
}
```

- [ ] **Step 2: 运行测试并确认因 `WidgetSnapshotStore` 缺失而失败**

```bash
xcodebuildmcp simulator test --project-path /Users/tigerguo/.codex/worktrees/76f2/HHappyDocs/HDiary.xcodeproj --scheme HDiary --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD --extra-args "-only-testing:HDiaryWidgetDataTests/WidgetSnapshotStoreTests"
```

Expected: FAIL，错误包含 `cannot find 'WidgetSnapshotStore' in scope`。

- [ ] **Step 3: 实现 actor 隔离的 replace/read**

```swift
import Foundation
import SwiftData

public actor WidgetSnapshotStore {
  private let modelContainer: ModelContainer

  public init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
  }

  public func replace(with snapshot: WidgetSnapshotValue) throws {
    let context = ModelContext(modelContainer)
    context.autosaveEnabled = false

    let existingParticipants = try context.fetch(FetchDescriptor<WidgetParticipantSnapshot>())
    let participantsByID = Dictionary(uniqueKeysWithValues: existingParticipants.map { ($0.uuid, $0) })
    let desiredParticipantIDs = Set(snapshot.participants.map(\.uuid))
    for value in snapshot.participants {
      if let model = participantsByID[value.uuid] {
        model.nickName = value.nickName
        model.avatarThumbnailData = value.avatarThumbnailData
      } else {
        context.insert(WidgetParticipantSnapshot(
          uuid: value.uuid,
          nickName: value.nickName,
          avatarThumbnailData: value.avatarThumbnailData
        ))
      }
    }
    for model in existingParticipants where !desiredParticipantIDs.contains(model.uuid) {
      context.delete(model)
    }

    let existingMoments = try context.fetch(FetchDescriptor<WidgetMomentSnapshot>())
    let momentsByID = Dictionary(uniqueKeysWithValues: existingMoments.map { ($0.uuid, $0) })
    let desiredMomentIDs = Set(snapshot.moments.map(\.uuid))
    for value in snapshot.moments {
      if let model = momentsByID[value.uuid] {
        model.timestamp = value.timestamp
        model.title = value.title
        model.participantIDs = value.participantIDs
      } else {
        context.insert(WidgetMomentSnapshot(
          uuid: value.uuid,
          timestamp: value.timestamp,
          title: value.title,
          participantIDs: value.participantIDs
        ))
      }
    }
    for model in existingMoments where !desiredMomentIDs.contains(model.uuid) {
      context.delete(model)
    }

    try context.save()
  }

  public func snapshot() throws -> WidgetSnapshotValue {
    let context = ModelContext(modelContainer)
    let participants = try context.fetch(FetchDescriptor<WidgetParticipantSnapshot>(
      sortBy: [SortDescriptor(\.nickName), SortDescriptor(\.uuid)]
    ))
    let moments = try context.fetch(FetchDescriptor<WidgetMomentSnapshot>(
      sortBy: [SortDescriptor(\.timestamp, order: .reverse), SortDescriptor(\.uuid)]
    ))
    return WidgetSnapshotValue(
      participants: participants.map(WidgetParticipantValue.init),
      moments: moments.map(WidgetMomentValue.init)
    )
  }
}
```

在 value types 中增加从 snapshot model 初始化的 public initializer。每次 replace 使用新 `ModelContext`，失败 context 直接释放，下一次调用不继承未保存状态。

- [ ] **Step 4: 运行存储测试并确认通过**

Run: 与 Step 2 相同。

Expected: PASS，replace 结果与第二份 snapshot 完全相等，reader save 抛错。

- [ ] **Step 5: 提交 Task 2**

```bash
git add HDiaryLibrary/Sources/HDiaryWidgetData/Storage/WidgetSnapshotStore.swift HDiaryLibrary/Sources/HDiaryWidgetData/Model/WidgetSnapshotValue.swift HDiaryLibrary/Tests/HDiaryWidgetDataTests/WidgetSnapshotStoreTests.swift
git commit -m "Add atomic widget snapshot replacement"
```

---

### Task 3: 从主 Store 生成有界 snapshot

**Files:**
- Create: `HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/WidgetSnapshotSource.swift`
- Create: `HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/WidgetAvatarThumbnailer.swift`
- Create: `HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/WidgetSnapshotProjector.swift`
- Create: `HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/MainStoreWidgetSnapshotBuilder.swift`
- Create: `HDiaryLibrary/Tests/HDiaryAppFeatureTests/WidgetSnapshotProjectorTests.swift`
- Modify: `HDiaryLibrary/Package.swift`

**Interfaces:**
- Consumes: `HDiaryModel.Participant`、`HDiaryModel.Moment`，但只在 `@MainActor` reader 内使用。
- Produces: `WidgetParticipantSource`、`WidgetMomentSource`，均为 `Sendable` values。
- Produces: `WidgetSnapshotProjector.project(participants:moments:limit:thumbnail:) async -> WidgetSnapshotValue`。
- Produces: `@MainActor MainStoreWidgetSnapshotBuilder.build() async throws -> WidgetSnapshotValue`。

- [ ] **Step 1: 写有界并集、删除过滤、多人去重和缩略图测试**

测试用以下 fixture 构造 2 位 Participant、各自 10 条 Moment、3 条无 Participant 的全局 Moment，以及 1 条 `isDeleted == true` 的 Moment：

```swift
let firstParticipantID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
let secondParticipantID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
let deletedID = UUID(uuidString: "00000000-0000-0000-0000-000000009999")!
let participants = [
  WidgetParticipantSource(uuid: firstParticipantID, nickName: "A", avatarData: Data([1, 2, 3])),
  WidgetParticipantSource(uuid: secondParticipantID, nickName: "B", avatarData: Data([4, 5, 6])),
]
var moments = [WidgetMomentSource]()
for index in 0 ..< 10 {
  moments.append(WidgetMomentSource(
    uuid: UUID(uuidString: String(format: "00000000-0000-0000-0001-%012d", index))!,
    timestamp: Date(timeIntervalSince1970: TimeInterval(1_000 - index)),
    title: "A-\(index)",
    participantIDs: [firstParticipantID],
    isDeleted: false
  ))
  moments.append(WidgetMomentSource(
    uuid: UUID(uuidString: String(format: "00000000-0000-0000-0002-%012d", index))!,
    timestamp: Date(timeIntervalSince1970: TimeInterval(900 - index)),
    title: "B-\(index)",
    participantIDs: [secondParticipantID],
    isDeleted: false
  ))
}
for index in 0 ..< 3 {
  moments.append(WidgetMomentSource(
    uuid: UUID(uuidString: String(format: "00000000-0000-0000-0003-%012d", index))!,
    timestamp: Date(timeIntervalSince1970: TimeInterval(800 - index)),
    title: "Global-\(index)",
    participantIDs: [],
    isDeleted: false
  ))
}
moments.append(WidgetMomentSource(
  uuid: deletedID,
  timestamp: Date(timeIntervalSince1970: 2_000),
  title: "Deleted",
  participantIDs: [firstParticipantID, secondParticipantID],
  isDeleted: true
))
```

再执行并断言：

```swift
let snapshot = await WidgetSnapshotProjector.project(
  participants: participants,
  moments: moments,
  limit: 8,
  thumbnail: { data in data.map { Data($0.prefix(2)) } }
)

XCTAssertEqual(snapshot.participants.count, 2)
XCTAssertTrue(snapshot.participants.allSatisfy { ($0.avatarThumbnailData?.count ?? 0) <= 2 })
XCTAssertFalse(snapshot.moments.contains { $0.uuid == deletedID })
XCTAssertEqual(Set(snapshot.moments.map(\.uuid)).count, snapshot.moments.count)
XCTAssertLessThanOrEqual(snapshot.moments.count, participants.count * 8 + 8)
XCTAssertEqual(snapshot.moments.filter { $0.participantIDs.contains(firstParticipantID) }.count, 8)
XCTAssertEqual(snapshot.moments.filter { $0.participantIDs.contains(secondParticipantID) }.count, 8)
```

另一个测试使用 512×256 的测试图，调用 live thumbnailer，解码后断言最长边为 64 px；无效 Data 返回 `nil`。

- [ ] **Step 2: 运行测试并确认投影 API 缺失**

```bash
xcodebuildmcp simulator test --project-path /Users/tigerguo/.codex/worktrees/76f2/HHappyDocs/HDiary.xcodeproj --scheme HDiary --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD --extra-args "-only-testing:HDiaryAppFeatureTests/WidgetSnapshotProjectorTests"
```

Expected: FAIL，错误包含 `cannot find 'WidgetSnapshotProjector' in scope`。

- [ ] **Step 3: 实现纯值投影**

Source values：

```swift
struct WidgetParticipantSource: Sendable, Equatable {
  let uuid: UUID
  let nickName: String
  let avatarData: Data?
}

struct WidgetMomentSource: Sendable, Equatable {
  let uuid: UUID
  let timestamp: Date
  let title: String
  let participantIDs: [UUID]
  let isDeleted: Bool
}
```

`WidgetSnapshotProjector` 先过滤 deleted，再按 `timestamp` 逆序、UUID 正序稳定排序；把全局 prefix(8) 和每位 Participant 对应 prefix(8) 放入 `[UUID: WidgetMomentSource]` 去重，最终再次按同样规则排序。Participant 按 `nickName.localizedStandardCompare`、UUID 排序。头像逐个调用注入的 async thumbnail closure。

`WidgetAvatarThumbnailer.thumbnailData(from:maxPixelSize:)` 标记 `@concurrent`，只接收和返回 `Data`；使用 ImageIO 从原始 Data 下采样到最长边 64 px，再编码 JPEG，输入为 `nil` 或无效图片时返回 `nil`。不让 `UIImage` 或 SwiftData model 跨 actor。

- [ ] **Step 4: 实现主 Store reader/builder**

`MainStoreWidgetSnapshotBuilder` 标记 `@MainActor`，持有 `ModelContainer`。每次 `build()` 创建独立 `ModelContext`，关闭 autosave，读取 Participant 和按时间逆序的 Moment，并设置：

```swift
momentDescriptor.relationshipKeyPathsForPrefetching = [\.participants]
```

在 `await` thumbnail/projector 前，把所有 model 转换成 `WidgetParticipantSource` 和 `WidgetMomentSource`。SwiftData models 和 `ModelContext` 不离开 MainActor。

- [ ] **Step 5: 运行投影测试并确认通过**

Run: 与 Step 2 相同。

Expected: PASS；上限、deleted 过滤、多人去重和 64 px 缩略全部通过。

- [ ] **Step 6: 提交 Task 3**

```bash
git add HDiaryLibrary/Package.swift HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot HDiaryLibrary/Tests/HDiaryAppFeatureTests/WidgetSnapshotProjectorTests.swift
git commit -m "Project bounded widget snapshots"
```

---

### Task 4: 串行重建、debounce 与成功后刷新 Widget

**Files:**
- Create: `HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/WidgetSnapshotCoordinator.swift`
- Create: `HDiaryLibrary/Tests/HDiaryAppFeatureTests/WidgetSnapshotCoordinatorTests.swift`

**Interfaces:**
- Consumes: `MainStoreWidgetSnapshotBuilder`、`WidgetSnapshotStore`。
- Produces: `@MainActor protocol WidgetSnapshotBuilding { func build() async throws -> WidgetSnapshotValue }`。
- Produces: `protocol WidgetSnapshotWriting: Sendable { func replace(with:) async throws }`。
- Produces: `@MainActor final class WidgetSnapshotCoordinator` 的 `requestRebuild() -> Task<Void, Never>` 和 `rebuildNow() async`。

- [ ] **Step 1: 写成功、失败、debounce 和运行中补跑测试**

测试文件定义以下 fakes：

```swift
enum TestError: Error { case build, write }

@MainActor
final class BuilderSpy: WidgetSnapshotBuilding {
  var buildCount = 0
  var result: Result<WidgetSnapshotValue, TestError>

  init(result: Result<WidgetSnapshotValue, TestError>) { self.result = result }

  func build() async throws -> WidgetSnapshotValue {
    buildCount += 1
    return try result.get()
  }
}

actor WriterSpy: WidgetSnapshotWriting {
  private(set) var snapshots = [WidgetSnapshotValue]()
  var error: TestError?

  init(error: TestError? = nil) { self.error = error }

  func replace(with snapshot: WidgetSnapshotValue) throws {
    if let error { throw error }
    snapshots.append(snapshot)
  }
}

@MainActor
final class ReloaderSpy {
  private(set) var reloadCount = 0
  func reload() { reloadCount += 1 }
}

extension WidgetSnapshotValue {
  static let fixture = WidgetSnapshotValue(participants: [], moments: [])
}
```

Coordinator initializer 接收 `sleep: @escaping @Sendable () async throws -> Void` 和
`reloadTimeline: @escaping @MainActor () -> Void`。成功与失败测试完整建立 dependencies：

```swift
@MainActor
func testSuccessfulRebuildWritesThenReloadsTimeline() async {
  let builder = BuilderSpy(result: .success(.fixture))
  let writer = WriterSpy()
  let reloader = ReloaderSpy()
  let coordinator = WidgetSnapshotCoordinator(
    builder: builder,
    writer: writer,
    sleep: {},
    reloadTimeline: reloader.reload
  )
  await coordinator.rebuildNow()
  let snapshots = await writer.snapshots
  XCTAssertEqual(snapshots, [.fixture])
  XCTAssertEqual(reloader.reloadCount, 1)
}

@MainActor
func testWriteFailureKeepsPreviousSnapshotAndDoesNotReload() async {
  let builder = BuilderSpy(result: .success(.fixture))
  let writer = WriterSpy(error: .write)
  let reloader = ReloaderSpy()
  let coordinator = WidgetSnapshotCoordinator(
    builder: builder,
    writer: writer,
    sleep: {},
    reloadTimeline: reloader.reload
  )
  await coordinator.rebuildNow()
  let snapshots = await writer.snapshots
  XCTAssertTrue(snapshots.isEmpty)
  XCTAssertEqual(reloader.reloadCount, 0)
}

@MainActor
func testTwoPendingRequestsCoalesceIntoOneRebuild() async {
  let builder = BuilderSpy(result: .success(.fixture))
  let writer = WriterSpy()
  let reloader = ReloaderSpy()
  let sleeper = ControlledDebounceSleeper()
  let coordinator = WidgetSnapshotCoordinator(
    builder: builder,
    writer: writer,
    sleep: sleeper.sleep,
    reloadTimeline: reloader.reload
  )
  let first = coordinator.requestRebuild()
  await sleeper.waitUntilSleeping()
  let second = coordinator.requestRebuild()
  await sleeper.waitUntilSleeping()
  await sleeper.releaseCurrentWaiter()
  await first.value
  await second.value
  XCTAssertEqual(builder.buildCount, 1)
}
```

`ControlledDebounceSleeper` 用递增 token 保存 `[Int: CheckedContinuation<Void, Error>]`；
`sleep()` 使用 `withTaskCancellationHandler`，取消时只恢复对应 token 为
`CancellationError`，不会误取消下一位 waiter。`waitUntilSleeping()` 自身也用 continuation，
不使用固定延迟。运行中补跑测试让另一版 writer fake 在 continuation 上暂停，期间调用
`requestRebuild()`；释放后断言总共执行 2 次，不丢最后状态。

- [ ] **Step 2: 运行测试并确认 coordinator 缺失**

```bash
xcodebuildmcp simulator test --project-path /Users/tigerguo/.codex/worktrees/76f2/HHappyDocs/HDiary.xcodeproj --scheme HDiary --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD --extra-args "-only-testing:HDiaryAppFeatureTests/WidgetSnapshotCoordinatorTests"
```

Expected: FAIL，错误包含 `cannot find 'WidgetSnapshotCoordinator' in scope`。

- [ ] **Step 3: 实现 coordinator 状态机**

`WidgetSnapshotCoordinator` 是 `@MainActor` 类型，内部状态固定为：

```swift
private var debounceTask: Task<Void, Never>?
private var isRebuilding = false
private var needsAnotherRebuild = false
```

live sleeper 为：

```swift
{ try await Task.sleep(for: .milliseconds(350)) }
```

`requestRebuild()` 取消旧 debounce task，创建继承 MainActor 的新 `Task`，等待后调用 `runRebuildLoop()`；`runRebuildLoop()` 若已经运行，只设置 `needsAnotherRebuild = true`。主循环每轮顺序必须为 build → writer.replace → timeline reload，任何错误只写 `Log.data.error`，不 reload。每轮结束检查 `needsAnotherRebuild`，必要时再执行一次。`isolated deinit` 取消 debounce task。

为 `MainStoreWidgetSnapshotBuilder` 和 `WidgetSnapshotStore` 增加上述协议 conformance。Live reloader 使用：

```swift
WidgetCenter.shared.reloadTimelines(ofKind: HDiaryIntentKind.moment.rawValue)
```

- [ ] **Step 4: 运行 coordinator 测试并确认通过**

Run: 与 Step 2 相同。

Expected: PASS；无 `Task.sleep` 固定延时测试，所有异步时点通过 continuation 控制。

- [ ] **Step 5: 提交 Task 4**

```bash
git add HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/WidgetSnapshotCoordinator.swift HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/MainStoreWidgetSnapshotBuilder.swift HDiaryLibrary/Tests/HDiaryAppFeatureTests/WidgetSnapshotCoordinatorTests.swift
git commit -m "Coordinate widget snapshot refreshes"
```

---

### Task 5: 让 Widget 只读取 snapshot Store

**Files:**
- Modify: `HDiaryLibrary/Package.swift`
- Modify: `HDiaryLibrary/Sources/HDiaryWidgetIntents/MomentWidget/MomentWidgetUtil.swift`
- Modify: `HDiaryLibrary/Sources/HDiaryWidgetIntents/MomentWidget/MomentWidgetIntent.swift`
- Modify: `HDiaryLibrary/Sources/HDiaryWidgetFeature/MomentWidget/MomentTimeLineProvider.swift`
- Modify: `HDiaryLibrary/Sources/HDiaryWidgetFeature/MomentWidget/MomentWidget.swift`
- Modify: `HDiaryLibrary/Sources/HDiaryModel/Model/Container/ModelContainer.swift`
- Modify: `HDiaryLibrary/Tests/HDiaryAppFeatureTests/MomentWidgetIntentTests.swift`
- Modify: `HDiaryWidgetExtension.entitlements`
- Modify: `HDiaryWidgetExtensionDebug.entitlements`

**Interfaces:**
- Consumes: `WidgetSnapshotContainer.makeReaderContainer()` 和 snapshot models。
- Produces: `@MainActor public final class MomentWidgetDataSource`。
- Produces: `fetchParticipants() throws -> [WidgetParticipantValue]`、`fetchMoments(participantID:) throws -> [WidgetMomentValue]`。

- [ ] **Step 1: 将旧容器断言改成独立 snapshot 行为测试**

删除 `testMomentWidgetModelContextUsesCurrentAppContainer`，改为使用临时 snapshot Store：writer 写入 2 个 Participant 和 3 个 Moment，reader data source 断言：

```swift
let dataSource = MomentWidgetDataSource(modelContainer: readerContainer)
let participants = try dataSource.fetchParticipants()
let selectedMoments = try dataSource.fetchMoments(participantID: firstParticipantID)
let allMoments = try dataSource.fetchMoments(participantID: .null)

XCTAssertEqual(participants.map(\.uuid), [firstParticipantID, secondParticipantID])
XCTAssertEqual(selectedMoments.map(\.uuid), [firstMomentID, sharedMomentID])
XCTAssertEqual(allMoments.count, 3)
XCTAssertNotEqual(readerContainer.configurations.first?.url, HDiaryContainer.iCloudConfiguration.url)
```

同时添加 `ParticipantEntity` 从 snapshot value 生成头像、昵称的测试。

- [ ] **Step 2: 运行测试并确认仍读取主模型或 API 缺失**

```bash
xcodebuildmcp simulator test --project-path /Users/tigerguo/.codex/worktrees/76f2/HHappyDocs/HDiary.xcodeproj --scheme HDiary --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD --extra-args "-only-testing:HDiaryAppFeatureTests/MomentWidgetIntentTests"
```

Expected: FAIL，错误包含 `cannot find 'MomentWidgetDataSource' in scope`。

- [ ] **Step 3: 修改 package 依赖形成编译期隔离**

- `HDiaryWidgetIntents` 删除 `HDiaryModel` 依赖，增加 `HDiaryWidgetData`。
- `HDiaryWidgetFeature` 删除 `HDiaryModel` 依赖，增加 `HDiaryWidgetData`。
- `HDiaryAppFeatureTests` 增加 `HDiaryWidgetData`。

这一步完成后，Widget 源码若仍引用 `Moment`、`Participant` 或 `HDiaryContainer` 会直接编译失败。

同时把主容器 closure 内的 configuration 提取为
`public static let iCloudConfiguration`，保持原有 schema、App Group 和 private CloudKit
identifier 不变；`iCloudContainer` 只消费这一份 configuration。测试只比较 configuration
URL，不为此初始化第二个 CloudKit container。

- [ ] **Step 4: 改写 Widget 数据源和展示映射**

`MomentWidgetDataSource` 持有 reader `ModelContainer`，所有方法 `@MainActor` 执行。Participant 按昵称排序；Moment 按 timestamp 逆序抓取后，在内存中按 `participantIDs.contains` 过滤，避免对 Codable array 使用不可靠 SwiftData predicate。

`MomentWidgetUtil` 使用一个 main-actor lazy reader；创建 reader 失败时记录 `OSLog` 并返回 `nil`。`ParticipantOptionsProvider`、timeline provider 遇到 `nil` 或 fetch error 时返回空/占位数据，绝不回退主 Store。

`ParticipantEntity.init(from value: WidgetParticipantValue)` 使用 thumbnail Data；无效或 nil 时回退 `.defaultPerson`。

- [ ] **Step 5: 删除 Widget CloudKit entitlement**

从两个 Widget entitlement 文件删除：

```text
com.apple.developer.icloud-container-identifiers
com.apple.developer.icloud-services
```

保留 `com.apple.security.application-groups`；Debug 文件现有 `aps-environment` 保持不变。

- [ ] **Step 6: 运行 Widget 测试和编译隔离检查**

Run: 与 Step 2 相同。

Run:

```bash
rg -n "import HDiaryModel|HDiaryContainer|getCurrentContainer|cloudKitDatabase" HDiaryLibrary/Sources/HDiaryWidgetIntents HDiaryLibrary/Sources/HDiaryWidgetFeature HDiaryWidget
```

Expected: 测试 PASS；`rg` 返回 exit 1 且无匹配。

- [ ] **Step 7: 提交 Task 5**

```bash
git add HDiaryLibrary/Package.swift HDiaryLibrary/Sources/HDiaryModel/Model/Container/ModelContainer.swift HDiaryLibrary/Sources/HDiaryWidgetIntents HDiaryLibrary/Sources/HDiaryWidgetFeature HDiaryLibrary/Tests/HDiaryAppFeatureTests/MomentWidgetIntentTests.swift HDiaryWidgetExtension.entitlements HDiaryWidgetExtensionDebug.entitlements
git commit -m "Read widgets from isolated snapshot store"
```

---

### Task 6: 持久化 CloudKit event 和 retry-after

**Files:**
- Create: `HDiaryLibrary/Sources/HDiaryAppFeature/CloudSyncDiagnostics/CloudSyncEventRecord.swift`
- Create: `HDiaryLibrary/Sources/HDiaryAppFeature/CloudSyncDiagnostics/CloudSyncErrorDetails.swift`
- Create: `HDiaryLibrary/Sources/HDiaryAppFeature/CloudSyncDiagnostics/CloudSyncDiagnosticsFileStore.swift`
- Create: `HDiaryLibrary/Sources/HDiaryAppFeature/CloudSyncDiagnostics/CloudSyncDiagnosticsModel.swift`
- Create: `HDiaryLibrary/Tests/HDiaryAppFeatureTests/CloudSyncDiagnosticsTests.swift`

**Interfaces:**
- Produces: `CloudSyncEventRecord: Codable, Sendable, Equatable, Identifiable`。
- Produces: `CloudSyncErrorDetails.from(error:now:)`。
- Produces: `actor CloudSyncDiagnosticsFileStore` 的 `upsert(_:)`、`load()`、`exportURL()`。
- Produces: `@MainActor @Observable CloudSyncDiagnosticsModel` 的 `record(_:) async`、`load() async`。

- [ ] **Step 1: 写 event 状态、嵌套 retry-after、100 条上限和损坏文件测试**

核心断言：

```swift
func testRetryAfterIsFoundInNestedPartialError() {
  let retrying = NSError(
    domain: CKErrorDomain,
    code: CKError.requestRateLimited.rawValue,
    userInfo: [CKErrorRetryAfterKey: NSNumber(value: 60)]
  )
  let outer = NSError(
    domain: CKErrorDomain,
    code: CKError.partialFailure.rawValue,
    userInfo: [CKPartialErrorsByItemIDKey: ["record": retrying]]
  )
  let now = Date(timeIntervalSince1970: 1_000)

  let details = CloudSyncErrorDetails.from(error: outer, now: now)

  XCTAssertEqual(details?.domain, CKErrorDomain)
  XCTAssertEqual(details?.code, CKError.partialFailure.rawValue)
  XCTAssertEqual(details?.retryAfter, 60)
  XCTAssertEqual(details?.retryDate, Date(timeIntervalSince1970: 1_060))
}
```

文件测试 upsert 同一 UUID 的 `.inProgress` 后再 `.succeeded`，断言只有一条且为 succeeded；写入 105 个不同 ID 后只剩最后 100 个；手工写入无效 JSON 后 `load()` 返回空数组，并生成唯一 `cloud-sync-events.corrupt.json`。

- [ ] **Step 2: 运行测试并确认诊断类型缺失**

```bash
xcodebuildmcp simulator test --project-path /Users/tigerguo/.codex/worktrees/76f2/HHappyDocs/HDiary.xcodeproj --scheme HDiary --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD --extra-args "-only-testing:HDiaryAppFeatureTests/CloudSyncDiagnosticsTests"
```

Expected: FAIL，错误包含 `cannot find 'CloudSyncErrorDetails' in scope`。

- [ ] **Step 3: 实现 Sendable 诊断记录与错误链解析**

```swift
struct CloudSyncEventRecord: Codable, Sendable, Equatable, Identifiable {
  enum Kind: String, Codable, Sendable { case setup, importData, export }
  enum State: String, Codable, Sendable { case inProgress, succeeded, failed }

  let id: UUID
  let storeIdentifier: String
  let kind: Kind
  let startDate: Date
  let endDate: Date?
  let state: State
  let error: CloudSyncErrorDetails?
}
```

`CloudSyncErrorDetails` 保存 `domain`、`code`、`message`、`retryAfter`、`retryDate`。解析顺序为当前 NSError、`NSUnderlyingErrorKey`、`NSMultipleUnderlyingErrorsKey`、`CKPartialErrorsByItemIDKey`；使用 visited `ObjectIdentifier` 防循环。只从 NSNumber 读取 `CKErrorRetryAfterKey`，负数忽略。

- [ ] **Step 4: 实现 actor 文件 Store**

默认目录：

```swift
AppConstants.groupContainerURL
  .appending(components: "Library", "Application Support", "Diagnostics", directoryHint: .isDirectory)
```

行为固定为：

- `load()` 不存在时返回 `[]`。
- decode 失败时，以原子 replace 方式覆盖唯一 `.corrupt.json`，然后返回 `[]`。
- `upsert` 按 ID 替换；若已有 ended record 而新 record 是 in-progress，不降级。
- 按 `startDate` 升序保存、只保留 suffix(100)。
- `JSONEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]`，日期使用 `.iso8601`。
- `Data.write(to:options: [.atomic])` 后在 iOS 设置 `.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication`。
- 目录 `isExcludedFromBackup = true`。
- `exportURL()` 确保稳定文件存在并返回 JSON URL。

- [ ] **Step 5: 实现 MainActor observable model**

`CloudSyncDiagnosticsModel` 持有 file store，公开：

```swift
private(set) var records: [CloudSyncEventRecord] = []
private(set) var loadErrorDescription: String?
private(set) var exportURL: URL?

func load() async
func record(_ event: CloudSyncEventRecord) async
```

actor 返回 `[CloudSyncEventRecord]` 后再更新 MainActor state；失败写 `Log.data.error` 并设置可展示错误，不吞掉。

- [ ] **Step 6: 运行诊断测试并确认通过**

Run: 与 Step 2 相同。

Expected: PASS；同 ID 合并、100 条上限、nested retry-after 和损坏隔离均通过。

- [ ] **Step 7: 提交 Task 6**

```bash
git add HDiaryLibrary/Sources/HDiaryAppFeature/CloudSyncDiagnostics HDiaryLibrary/Tests/HDiaryAppFeatureTests/CloudSyncDiagnosticsTests.swift
git commit -m "Persist CloudKit sync diagnostics"
```

---

### Task 7: 安装 CloudKit/remote/local 观察器并连接 snapshot

**Files:**
- Create: `HDiaryLibrary/Sources/HDiaryAppFeature/CloudSyncDiagnostics/CloudSyncMonitor.swift`
- Create: `HDiaryLibrary/Sources/HDiaryAppFeature/CloudSyncDiagnostics/CloudSyncRuntime.swift`
- Create: `HDiaryLibrary/Tests/HDiaryAppFeatureTests/CloudSyncMonitorTests.swift`
- Modify: `HDiaryLibrary/Sources/HDiaryModel/Model/Container/ModelContainer.swift`
- Modify: `HDiaryLibrary/Sources/HDiaryAppFeature/HDiaryApp.swift`
- Modify: `HDiaryLibrary/Sources/HDiaryAppFeature/Common/Navigation/AppEnvironments.swift`

**Interfaces:**
- Consumes: `CloudSyncDiagnosticsModel`、`WidgetSnapshotCoordinator`。
- Produces: `CloudSyncEventRecord.init(event:now:)` adapter，只在 MainActor 接触 Core Data event object。
- Produces: `CloudSyncMonitor.startEventObservation()`、`attach(primaryContainer:coordinator:)`、`stop()`。
- Produces: idempotent `CloudSyncRuntime.start()`。

- [ ] **Step 1: 写 event mapping、Store URL 过滤、local container 过滤和 runtime 幂等测试**

通过纯 input adapter 测 setup/import/export、in-progress/succeeded/failed。Remote change 使用构造的 Notification：

```swift
let matching = Notification(
  name: .NSPersistentStoreRemoteChange,
  object: nil,
  userInfo: [NSPersistentStoreURLKey: primaryStoreURL]
)
let other = Notification(
  name: .NSPersistentStoreRemoteChange,
  object: nil,
  userInfo: [NSPersistentStoreURLKey: snapshotStoreURL]
)

XCTAssertTrue(CloudSyncMonitor.matchesRemoteChange(matching, storeURL: primaryStoreURL))
XCTAssertFalse(CloudSyncMonitor.matchesRemoteChange(other, storeURL: primaryStoreURL))
```

Runtime 使用 injected factories，调用 `start()` 两次，断言只安装一次 observers、只请求一次 initial rebuild。

- [ ] **Step 2: 运行测试并确认 monitor 缺失**

```bash
xcodebuildmcp simulator test --project-path /Users/tigerguo/.codex/worktrees/76f2/HHappyDocs/HDiary.xcodeproj --scheme HDiary --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD --extra-args "-only-testing:HDiaryAppFeatureTests/CloudSyncMonitorTests"
```

Expected: FAIL，错误包含 `cannot find 'CloudSyncMonitor' in scope`。

- [ ] **Step 3: 统一主 App 当前容器入口**

Task 5 已提取 `iCloudConfiguration`。本步新增
`@MainActor public static var currentContainer: ModelContainer`，让
`getCurrentContainer()` 和 `withModelContainer()` 都委托它，避免 Debug 选择分叉。Widget
targets 已不依赖该模块。

- [ ] **Step 4: 使用 Combine 在 MainActor 接收通知**

`CloudSyncMonitor` 是 `@MainActor final class`，保存 `Set<AnyCancellable>`。`startEventObservation()` 必须先执行：

```swift
NotificationCenter.default.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
  .receive(on: RunLoop.main)
  .compactMap { $0.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event }
  .sink { [weak self] event in self?.record(event) }
  .store(in: &cancellables)
```

`record(event)` 在 MainActor 同步复制成 `CloudSyncEventRecord`，再创建继承 MainActor 的 Task 调用 diagnostics model。不得把 Core Data Event 跨 actor。

`attach` 再安装：

- `.NSPersistentStoreRemoteChange` publisher：提取 URL，只有与 `primaryContainer.configurations.first?.url` 一致时 request rebuild。
- `ModelContext.didSave` publisher：`notification.object as? ModelContext` 的 container 与 primary container identity 相同才 request rebuild；snapshot writer save 被过滤。

所有 publisher 都 `.receive(on: RunLoop.main)`；`stop()` 清空 cancellables。

- [ ] **Step 5: 确保观察器先于 CloudKit 容器初始化**

`CloudSyncRuntime.start()` 顺序固定：

1. 检查 `hasStarted` 并置 true。
2. `monitor.startEventObservation()`。
3. 访问 `HDiaryContainer.currentContainer`。
4. 创建 snapshot writer container/store、builder、coordinator。
5. `monitor.attach(primaryContainer:coordinator:)`。
6. `coordinator.requestRebuild()`。

任何 snapshot 初始化失败只记录错误，主 App 仍使用主容器启动。`HDiaryFeatureApp.init()` 调用 `CloudSyncRuntime.shared.start()`；其执行早于 `body` 中 `.withModelContainer()`。

- [ ] **Step 6: 运行 monitor 测试和相关 snapshot 测试**

```bash
xcodebuildmcp simulator test --project-path /Users/tigerguo/.codex/worktrees/76f2/HHappyDocs/HDiary.xcodeproj --scheme HDiary --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD --extra-args "-only-testing:HDiaryAppFeatureTests/CloudSyncMonitorTests" "-only-testing:HDiaryAppFeatureTests/WidgetSnapshotCoordinatorTests"
```

Expected: PASS；重复 start 不重复监听，remote/local 只匹配主 Store。

- [ ] **Step 7: 提交 Task 7**

```bash
git add HDiaryLibrary/Sources/HDiaryModel/Model/Container/ModelContainer.swift HDiaryLibrary/Sources/HDiaryAppFeature/CloudSyncDiagnostics/CloudSyncMonitor.swift HDiaryLibrary/Sources/HDiaryAppFeature/CloudSyncDiagnostics/CloudSyncRuntime.swift HDiaryLibrary/Sources/HDiaryAppFeature/HDiaryApp.swift HDiaryLibrary/Sources/HDiaryAppFeature/Common/Navigation/AppEnvironments.swift HDiaryLibrary/Tests/HDiaryAppFeatureTests/CloudSyncMonitorTests.swift
git commit -m "Observe CloudKit changes and refresh snapshots"
```

---

### Task 8: 增加 TestFlight/正式版同步诊断页面

**Files:**
- Create: `HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Data/CloudData/Diagnostics/CloudSyncDiagnosticsScreen.swift`
- Create: `HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Data/CloudData/Diagnostics/CloudSyncEventRow.swift`
- Create: `HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Data/CloudData/Diagnostics/CloudSyncDiagnosticsEmptyView.swift`
- Modify: `HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Data/CloudData/Entry/CloudDataEntryScreen.swift`
- Modify: `HDiaryLibrary/Sources/HDiaryAppFeature/Common/Navigation/HDiaryNavigatorModifier.swift`
- Modify: `HDiaryLibrary/Sources/HDiaryAppFeature/Common/DiaryStringKey.swift`
- Modify: `HDiary/Localizable.xcstrings`
- Modify: `HDiaryLibrary/Tests/HDiaryAppFeatureTests/CloudSyncDiagnosticsTests.swift`

**Interfaces:**
- Consumes: `CloudSyncDiagnosticsModel.records/loadErrorDescription/exportURL`。
- Produces: `HDiaryDestination.cloudSyncDiagnostics`。
- Produces: 用户可见的 event list 与 `ShareLink(item: URL)`。

- [ ] **Step 1: 先测试 UI presentation value**

把 row 所需的纯展示映射放进 `CloudSyncEventPresentation`。测试文件用固定时间和以下
fixture factory 创建 `.inProgressImport`、`.successfulExport`、`.failedSetup`、`.rateLimited`：

```swift
private let fixedStart = Date(timeIntervalSince1970: 1_000)
private let expectedRetryDate = Date(timeIntervalSince1970: 1_060)

private func record(
  id: Int,
  kind: CloudSyncEventRecord.Kind,
  state: CloudSyncEventRecord.State,
  error: CloudSyncErrorDetails? = nil
) -> CloudSyncEventRecord {
  CloudSyncEventRecord(
    id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", id))!,
    storeIdentifier: "primary",
    kind: kind,
    startDate: fixedStart,
    endDate: state == .inProgress ? nil : fixedStart.addingTimeInterval(10),
    state: state,
    error: error
  )
}
```

然后断言：

```swift
let inProgressImport = record(id: 1, kind: .importData, state: .inProgress)
let successfulExport = record(id: 2, kind: .export, state: .succeeded)
let failedSetup = record(
  id: 3,
  kind: .setup,
  state: .failed,
  error: CloudSyncErrorDetails(
    domain: NSCocoaErrorDomain,
    code: 134410,
    message: "CloudKit setup failed",
    retryAfter: nil,
    retryDate: nil
  )
)
let rateLimited = record(
  id: 4,
  kind: .export,
  state: .failed,
  error: CloudSyncErrorDetails(
    domain: CKErrorDomain,
    code: CKError.requestRateLimited.rawValue,
    message: "Request rate limited",
    retryAfter: 60,
    retryDate: expectedRetryDate
  )
)

XCTAssertEqual(CloudSyncEventPresentation(record: inProgressImport).state, .inProgress)
XCTAssertEqual(CloudSyncEventPresentation(record: successfulExport).state, .succeeded)
XCTAssertEqual(CloudSyncEventPresentation(record: failedSetup).errorCodeText, "NSCocoaErrorDomain 134410")
XCTAssertEqual(CloudSyncEventPresentation(record: rateLimited).retryDate, expectedRetryDate)
```

测试只断言语义值，不实例化 SwiftUI body。

- [ ] **Step 2: 运行 presentation 测试并确认失败**

```bash
xcodebuildmcp simulator test --project-path /Users/tigerguo/.codex/worktrees/76f2/HHappyDocs/HDiary.xcodeproj --scheme HDiary --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD --extra-args "-only-testing:HDiaryAppFeatureTests/CloudSyncDiagnosticsTests"
```

Expected: FAIL，错误包含 `cannot find 'CloudSyncEventPresentation' in scope`。

- [ ] **Step 3: 实现三个小型 SwiftUI View**

`CloudSyncEventPresentation` 暴露语义 `state`、`kind`、`errorCodeText`、`retryDate`，不在
model 中硬编码英文；View 根据 `state` 选择 `DiaryStringKey`。`CloudSyncDiagnosticsScreen`：

- `@State private var model = CloudSyncDiagnosticsModel.shared`。
- `List` 中先显示 load error（若有），再按 `startDate` 逆序显示 `CloudSyncEventRow`。
- records 为空且无 error 时显示 `CloudSyncDiagnosticsEmptyView`。
- `.task { await model.load() }`，不用 `onAppear { Task {} }`。
- toolbar 仅在 `exportURL != nil` 时显示 `ShareLink(item:)`，label 使用文字和 `square.and.arrow.up`，保持 VoiceOver 文本。

`CloudSyncEventRow` 使用系统 `.headline`、`.subheadline`、`.caption`，不写死字号；状态同时显示 symbol 和文字，不只依赖颜色。正在执行显示类型与开始时间，不使用无限 ProgressView。失败显示 domain/code/message；retryDate 存在时显示绝对时间。

`CloudSyncDiagnosticsEmptyView` 使用 `ContentUnavailableView`，标题“暂无同步事件”，说明“启动 iCloud 同步后，setup、import 和 export 会显示在这里”。

- [ ] **Step 4: 接入导航和正式可见入口**

`CloudDataEntryScreen` 的 `List` 增加第一个 Section：

```swift
Section {
  NavigationLink(value: HDiaryDestination.cloudSyncDiagnostics) {
    Label(DiaryStringKey.Data.CloudData.Diagnostics.title, systemImage: "waveform.path.ecg")
  }
}
```

入口不放在 `#if DEBUG`。`HDiaryDestination` 增加 `.cloudSyncDiagnostics` 并返回 `CloudSyncDiagnosticsScreen()`。

- [ ] **Step 5: 添加明确的英文和简体中文字符串**

在 `DiaryStringKey.Data.CloudData.Diagnostics` 定义并在 `HDiary/Localizable.xcstrings` 添加：

| Key | English | zh-Hans |
|---|---|---|
| `CloudSyncDiagnostics.title` | Sync Diagnostics | 同步诊断 |
| `CloudSyncDiagnostics.empty.title` | No Sync Events | 暂无同步事件 |
| `CloudSyncDiagnostics.empty.message` | Setup, import, and export events appear here after iCloud sync starts. | iCloud 同步开始后，setup、import 和 export 事件会显示在这里。 |
| `CloudSyncDiagnostics.status.inProgress` | In progress | 进行中 |
| `CloudSyncDiagnostics.status.succeeded` | Succeeded | 成功 |
| `CloudSyncDiagnostics.status.failed` | Failed | 失败 |
| `CloudSyncDiagnostics.retryAt` | Suggested retry time | 建议重试时间 |
| `CloudSyncDiagnostics.share` | Share diagnostics | 分享诊断文件 |
| `CloudSyncDiagnostics.loadFailed` | Failed to load diagnostics | 诊断记录加载失败 |

setup/import/export 技术类型保持英文，错误 description 使用系统提供文本。

- [ ] **Step 6: 运行诊断测试并确认通过**

Run: 与 Step 2 相同。

Expected: PASS；presentation 状态、错误 code 和 retry date 全部正确。

- [ ] **Step 7: 提交 Task 8**

```bash
git add HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Data/CloudData HDiaryLibrary/Sources/HDiaryAppFeature/Common/Navigation/HDiaryNavigatorModifier.swift HDiaryLibrary/Sources/HDiaryAppFeature/Common/DiaryStringKey.swift HDiary/Localizable.xcstrings HDiaryLibrary/Tests/HDiaryAppFeatureTests/CloudSyncDiagnosticsTests.swift
git commit -m "Show exportable cloud sync diagnostics"
```

---

### Task 9: 全量验证、运行态检查与代码复核

**Files:**
- Verify only; production/test changes仅在验证发现真实缺陷时回到对应 Task 的 TDD 循环。

**Interfaces:**
- Consumes: Tasks 1–8 的全部行为。
- Produces: 本地自动化证据、模拟器运行证据、TestFlight 验收清单。

- [ ] **Step 1: 静态检查 Store 隔离和 entitlements**

```bash
git diff --check
rg -n "import HDiaryModel|HDiaryContainer|getCurrentContainer|cloudKitDatabase" HDiaryLibrary/Sources/HDiaryWidgetIntents HDiaryLibrary/Sources/HDiaryWidgetFeature HDiaryWidget
plutil -p HDiaryWidgetExtension.entitlements
plutil -p HDiaryWidgetExtensionDebug.entitlements
```

Expected:

- `git diff --check` exit 0。
- `rg` 无匹配并返回 exit 1。
- 两个 Widget entitlement 都只有 App Group（Debug 可额外有现有 APS），没有 iCloud container/service。

- [ ] **Step 2: 运行 snapshot 与诊断目标测试**

```bash
xcodebuildmcp simulator test --project-path /Users/tigerguo/.codex/worktrees/76f2/HHappyDocs/HDiary.xcodeproj --scheme HDiary --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD --extra-args "-only-testing:HDiaryWidgetDataTests" "-only-testing:HDiaryAppFeatureTests/MomentWidgetIntentTests" "-only-testing:HDiaryAppFeatureTests/WidgetSnapshotProjectorTests" "-only-testing:HDiaryAppFeatureTests/WidgetSnapshotCoordinatorTests" "-only-testing:HDiaryAppFeatureTests/CloudSyncDiagnosticsTests" "-only-testing:HDiaryAppFeatureTests/CloudSyncMonitorTests"
```

Expected: 所列 tests 全部通过，0 failures。

- [ ] **Step 3: 运行完整 HDiary test plan**

```bash
xcodebuildmcp simulator test --project-path /Users/tigerguo/.codex/worktrees/76f2/HHappyDocs/HDiary.xcodeproj --scheme HDiary --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD
```

Expected: 所有非 UI test targets 通过，0 failures；记录 discovered/executed 数量，不把 test plan 排除项误报为失败。

- [ ] **Step 4: Build-and-run 并检查诊断页面**

```bash
RUN_OUTPUT=/tmp/hdiary-widget-snapshot-build-run.txt
xcodebuildmcp simulator build-and-run --project-path /Users/tigerguo/.codex/worktrees/76f2/HHappyDocs/HDiary.xcodeproj --scheme HDiary --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD | tee "$RUN_OUTPUT"
```

然后使用 `xcodebuildmcp ui-automation snapshot-ui --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD` 获取实时 elementRef，依次进入“设置”→“云端数据”→“同步诊断”；每次导航后重新 snapshot，不复用旧 ref。确认：

- 诊断入口在非 Debug-only section 的云端数据页中。
- 无 event 时显示“暂无同步事件”，不显示无限同步 spinner。
- 分享按钮有 VoiceOver label；存在 JSON 后可以唤起系统分享页。

- [ ] **Step 5: 检查运行日志和 snapshot 文件**

从 build-and-run 输出提取 log file path，然后：

```bash
RUNTIME_LOG=$(rg -o '/[^[:space:]]+\.log' /tmp/hdiary-widget-snapshot-build-run.txt | tail -1)
test -n "$RUNTIME_LOG"
test -f "$RUNTIME_LOG"
rg -n "134410|another instance of this persistent store actively syncing|CloudKit setup failed" "$RUNTIME_LOG"
```

Expected: 无匹配。再确认 App Group 中 snapshot SQLite 与主 Store URL 不同，`cloud-sync-events.json` 可解析且每条只包含设计字段。运行日志无匹配只能证明本次模拟器会话，没有替代 TestFlight 真机验收。

- [ ] **Step 6: 使用 `requesting-code-review` 做两轮复核**

第一轮逐条核对 spec：Store ownership、数据上限、失败保留、remote filtering、诊断脱敏、正式入口。第二轮专查 Swift 6 concurrency：ModelContext/model 不跨 actor、event object 在 MainActor 映射、无 `@unchecked Sendable`、actor reentrancy 不覆盖 ended event。

发现问题时回到对应 Task：先增加能失败的 regression test，再改实现并重跑该 Task 与完整测试。

- [ ] **Step 7: 按 `verification-before-completion` 做最终新鲜验证**

在最终交付所在消息前重新执行 Step 1、Step 2、Step 3，并检查：

```bash
git status --short --branch
git log --oneline --decorate -12
```

只根据该次输出报告通过数量、工作区状态和提交列表。

- [ ] **Step 8: 记录 TestFlight 真机最终验收项**

交付中明确列出发布后必须验证：

1. 干净安装后完成 production CloudKit 首次 import。
2. App 与 Widget 并发运行日志不再出现 134410。
3. setup/import/export 失败在诊断页显示 domain、code、retry-after。
4. 导出的 JSON 不包含用户内容。
5. 重复 Moment 是否仍出现；若出现，使用 recordID、CD_uuid 和诊断 JSON 建立新的根因证据。

本地不能验证以上生产环境事实，不把它们声明为已经通过。
