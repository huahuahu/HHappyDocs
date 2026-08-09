# Widget 独立快照实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让 Widget 完全脱离主 CloudKit Store，改读独立、有界、只读的 snapshot Store。

**Architecture:** 新增不依赖主业务模型的 `HDiaryWidgetData` target，主 App 将必要的 Participant 和 Moment 摘要投影到独立 App Group Store，Widget 仅以 `allowsSave: false` 读取。主 Store fetch 由专用 SourceReader actor 独占：Participant 全量读取，Moment 使用一次全局 Top-N 与每位 Participant 一次 Top-N 的 Store 层有界查询；Builder 是 `nonisolated`、`Sendable` value，使用 `@concurrent build()` 编排；Coordinator 仍由 MainActor 隔离。主 App 监听主 Store 本地保存与远端变化，触发 snapshot 重建与 Widget timeline 刷新。

**Tech Stack:** Swift 6.3、SwiftData、Swift Concurrency、Combine、Core Data notifications、WidgetKit、SwiftUI、XCTest、XcodeBuildMCP CLI 2.6.2。

## Global Constraints

- 保持 `HDiaryLibrary/Package.swift` 的 `.iOS(.v17)`、`.macOS(.v14)`、Swift 6 language mode、Strict Concurrency。
- 新增 `HDiaryAppFeature`、`HDiaryWidgetIntents`、`HDiaryWidgetFeature` 和对应测试源码沿用 `#if os(iOS)`；纯 `HDiaryWidgetData` target 同时编译 iOS 17 与 macOS 14。
- 不添加第三方依赖，不修改主 CloudKit container identifier 或生产 schema。
- Widget 不得导入 `HDiaryModel`、不得打开主 Store、不得持有 CloudKit entitlement。
- Snapshot Store 固定使用不同 URL、`cloudKitDatabase: .none`；reader 为 `allowsSave: false`，writer 为 `allowsSave: true`。
- Snapshot 保存全部 Participant，但只保存全局最近 8 条与每位 Participant 最近 8 条 Moment 的去重并集。
- 主 Store Moment 查询在 Store predicate 中排除 `markedAsDelete`；全局与每位 Participant 查询均设置 `fetchLimit = 8`，结果按 UUID 去重。
- 接受 P+1 次 Moment 查询来限制显式完整 Moment 查询结果；不使用会在访问字段时触发逐对象补查的 `propertiesToFetch`，也不承诺 `ModelContext` 内部 fault 严格有界。
- Snapshot 不保存正文、媒体、标签、评分或原始头像；头像缩略图最长边固定为 64 px。
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
- `HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/MainStoreWidgetSnapshotSourceReader.swift`：actor 内独占主 Store fetch 和 model-to-value 映射。
- `HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/MainStoreWidgetSnapshotBuilder.swift`：`nonisolated`、`Sendable` value，以 `@concurrent build()` 编排 reader、projector 和 thumbnailer。
- `HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/WidgetSnapshotCoordinator.swift`：debounce、串行重建、成功后刷新 timeline。
- `HDiaryLibrary/Tests/HDiaryAppFeatureTests/WidgetSnapshotProjectorTests.swift`：投影边界测试。
- `HDiaryLibrary/Tests/HDiaryAppFeatureTests/WidgetSnapshotCoordinatorTests.swift`：触发、合并和失败测试。

### 新增 snapshot 运行时

- `HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/WidgetSnapshotChangeMonitor.swift`：过滤主 Store remote change 和 local save。
- `HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/WidgetSnapshotRuntime.swift`：创建 coordinator、安装观察器并请求初始快照。
- `HDiaryLibrary/Tests/HDiaryAppFeatureTests/WidgetSnapshotChangeMonitorTests.swift`：通知过滤、并发边界与运行时幂等测试。

### 修改现有文件

- `HDiaryLibrary/Package.swift`：增加 product/targets，调整 Widget target 依赖。
- `HDiary.xctestplan`：纳入 `HDiaryWidgetDataTests`。
- `HDiaryLibrary/Sources/HDiaryModel/Model/Container/ModelContainer.swift`：公开稳定的主 Store configuration/URL，容器仍只在主 App 使用。
- `HDiaryLibrary/Sources/HDiaryWidgetIntents/MomentWidget/MomentWidgetUtil.swift`：改成 snapshot data source。
- `HDiaryLibrary/Sources/HDiaryWidgetIntents/MomentWidget/MomentWidgetIntent.swift`：Participant options 改读 snapshot。
- `HDiaryLibrary/Sources/HDiaryWidgetFeature/MomentWidget/MomentTimeLineProvider.swift`：timeline 改读 snapshot。
- `HDiaryLibrary/Tests/HDiaryAppFeatureTests/MomentWidgetIntentTests.swift`：改为独立 Store 读取测试。
- `HDiaryLibrary/Sources/HDiaryAppFeature/HDiaryApp.swift`：启动 Widget snapshot runtime。
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
- Create: `HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/MainStoreWidgetSnapshotSourceReader.swift`
- Create: `HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/MainStoreWidgetSnapshotBuilder.swift`
- Create: `HDiaryLibrary/Tests/HDiaryAppFeatureTests/WidgetSnapshotProjectorTests.swift`
- Create: `HDiaryLibrary/Tests/HDiaryAppFeatureTests/MainStoreWidgetSnapshotSourceReaderTests.swift`
- Modify: `HDiaryLibrary/Package.swift`

**Interfaces:**
- Consumes: `HDiaryModel.Participant`、`HDiaryModel.Moment`，但只在 `MainStoreWidgetSnapshotSourceReader` actor 内使用。
- Produces: `WidgetParticipantSource`、`WidgetMomentSource`，均为 `Sendable` values。
- Produces: `MainStoreWidgetSnapshotSourceReader.read(limit:)`；返回全部 Participant 和有界、按 UUID 去重的有效 Moment source values。
- Produces: `WidgetSnapshotProjector.project(participants:moments:limit:thumbnail:) async -> WidgetSnapshotValue`。
- Produces: `nonisolated`、`Sendable` 的 `MainStoreWidgetSnapshotBuilder`，以及 `@concurrent build() async throws -> WidgetSnapshotValue`。

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

- [ ] **Step 4: 实现主 Store 有界 reader/builder**

`MainStoreWidgetSnapshotSourceReader` actor 持有可跨 actor 的 `ModelContainer`。每次
`read(limit:)` 在 actor 内创建独立 `ModelContext` 并关闭 autosave：

- 全量读取 Participant，保证 Widget 配置选项完整。
- 当 `limit > 0` 时，用 `!moment.markedAsDelete` predicate 查询全局最近 `limit` 条 Moment。
- 再为每位 Participant 执行一次 relationship predicate 查询，读取最近 `limit` 条有效 Moment。
- 每个 Moment descriptor 都按 timestamp 倒序、UUID 正序排序，设置 `fetchLimit = limit`，并预取
  `Moment.participants`。
- 把全局和各 Participant 的结果按 Moment UUID 合并；全局查询负责保留无 Participant 的最近
  Moment，同一多人 Moment 即使被多个查询命中也只保留一次。
- `limit <= 0` 时仍返回全部 Participant，Moment 返回空数组。

Reader 在返回前把 model 转换成 `WidgetParticipantSource`、`WidgetMomentSource` 和聚合的
`WidgetSnapshotSourceValue`；SwiftData models 与 `ModelContext` 不离开 Reader actor。不要设置
`propertiesToFetch`：当前映射访问多个 Moment 字段和 relationship，SwiftData `@Model` partial
fetch 会在访问未取字段时逐对象补查完整行。P+1 查询限制的是显式完整 Moment 查询的结果数量，
不承诺 context 内部 relationship fault 严格有界。

为 Reader 增加真实 in-memory SwiftData 测试，覆盖 Store 层删除过滤、全局与每位 Participant
Top-N、UUID 去重、无 Participant 的全局 Moment，以及 `limit == 0`。

`WidgetSnapshotBuilding` 定义为 `nonisolated protocol WidgetSnapshotBuilding: Sendable`。
`MainStoreWidgetSnapshotBuilder` 是 `nonisolated`、`Sendable` value，持有 SourceReader actor，
`build()` 标记 `@concurrent`，定义一次 `limit = 8`，把同一 limit 同时传给 `read(limit:)` 和
Projector，只负责等待 Sendable source values 并编排 Projector 与 thumbnailer。
由于 `HDiaryAppFeature` 使用默认 MainActor isolation，不能只省略 `@MainActor`，必须显式声明
`nonisolated`。

- [ ] **Step 5: 运行投影测试并确认通过**

Run: 与 Step 2 相同。

Expected: PASS；Reader 的 Store 层上限、deleted 过滤、多人去重、无 Participant 全局记录，以及
Projector 与 64 px 缩略全部通过。

- [ ] **Step 6: 提交 Task 3**

```bash
git add HDiaryLibrary/Package.swift HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot HDiaryLibrary/Tests/HDiaryAppFeatureTests/WidgetSnapshotProjectorTests.swift HDiaryLibrary/Tests/HDiaryAppFeatureTests/MainStoreWidgetSnapshotSourceReaderTests.swift
git commit -m "Project bounded widget snapshots"
```

---

### Task 4: 串行重建、debounce 与成功后刷新 Widget

**Files:**
- Create: `HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/WidgetSnapshotCoordinator.swift`
- Create: `HDiaryLibrary/Tests/HDiaryAppFeatureTests/WidgetSnapshotCoordinatorTests.swift`

**Interfaces:**
- Consumes: `MainStoreWidgetSnapshotBuilder`、`WidgetSnapshotStore`。
- Produces: `nonisolated protocol WidgetSnapshotBuilding: Sendable { func build() async throws -> WidgetSnapshotValue }`。
- Produces: `protocol WidgetSnapshotWriting: Sendable { func replace(with:) async throws }`。
- Produces: `@MainActor final class WidgetSnapshotCoordinator` 的 `requestRebuild() -> Task<Void, Never>` 和 `rebuildNow() async`。

- [ ] **Step 1: 写成功、失败、debounce 和运行中补跑测试**

测试文件定义以下 fakes：

```swift
enum TestError: Error { case build, write }

actor BuilderSpy: WidgetSnapshotBuilding {
  private(set) var buildCount = 0
  private var result: Result<WidgetSnapshotValue, TestError>

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
  let buildCount = await builder.buildCount
  XCTAssertEqual(buildCount, 1)
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

`requestRebuild()` 取消旧 debounce task，创建继承 MainActor 的新 `Task`，等待后调用 `runRebuildLoop()`；`runRebuildLoop()` 若已经运行，只设置 `needsAnotherRebuild = true`。主循环每轮顺序必须为 build → writer.replace → timeline reload；Coordinator 状态仍留在 MainActor，但生产 Builder 的 `@concurrent build()` 不继承该 isolation。任何错误只写 `Log.data.error`，不 reload。每轮结束检查 `needsAnotherRebuild`，必要时再执行一次。`isolated deinit` 取消 debounce task。

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


### Task 6: 安装 snapshot 变更观察器并连接 runtime

**Files:**
- Create: `HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/WidgetSnapshotChangeMonitor.swift`
- Create: `HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/WidgetSnapshotRuntime.swift`
- Create: `HDiaryLibrary/Tests/HDiaryAppFeatureTests/WidgetSnapshotChangeMonitorTests.swift`
- Modify: `HDiaryLibrary/Sources/HDiaryModel/Model/Container/ModelContainer.swift`
- Modify: `HDiaryLibrary/Sources/HDiaryAppFeature/HDiaryApp.swift`
- Modify: `HDiaryLibrary/Sources/HDiaryAppFeature/Common/Navigation/AppEnvironments.swift`

**Interfaces:**
- Produces: `WidgetSnapshotChangeMonitor.attach(primaryContainer:coordinator:)` 和 `stop()`。
- Produces: idempotent `WidgetSnapshotRuntime.start()`。
- Preserves: 通知发布 actor 上先提取 Sendable URL/`ObjectIdentifier`，不跨 actor 发送 `ModelContext`。

- [ ] **Step 1: 写 Store URL、local container 过滤和 runtime 幂等测试**

覆盖主 Store remote change、其他 Store remote change、主容器本地保存、其他容器保存，以及重复
`start()` 只安装一次观察器并请求一次 initial rebuild。

- [ ] **Step 2: 运行测试并确认新 monitor/runtime 缺失**

使用 XcodeBuildMCP 只运行 `HDiaryAppFeatureTests/WidgetSnapshotChangeMonitorTests`。

Expected: FAIL，错误包含 `cannot find 'WidgetSnapshotChangeMonitor' in scope` 或缺少
`WidgetSnapshotRuntime`。

- [ ] **Step 3: 统一主 App 当前容器入口**

让 `getCurrentContainer()` 和 `withModelContainer()` 都委托
`HDiaryContainer.currentContainer`，保证 runtime 与 SwiftUI 使用同一个主容器实例。

- [ ] **Step 4: 使用 Combine 监听 snapshot 触发源**

`WidgetSnapshotChangeMonitor` 保持 MainActor 隔离并监听：

- `NSPersistentStoreRemoteChange`：在切换到主 RunLoop 前提取 URL，只接受主 Store URL。
- `ModelContext.didSave`：在切换到主 RunLoop 前提取 container identity，只接受主容器。

其他 Store（包括 snapshot Store）的通知必须被过滤，避免重建循环。

- [ ] **Step 5: 启动 runtime**

`WidgetSnapshotRuntime.start()` 固定执行：读取当前主容器、创建 coordinator、强持有 coordinator、
安装观察器、请求 initial rebuild。Snapshot 初始化失败只记录错误，不阻止主 App 启动。

- [ ] **Step 6: 运行 monitor 与 coordinator 测试**

Expected: 通知过滤、初始重建、debounce、dirty 补跑和失败语义全部通过。

---

### Task 7: 全量验证与代码复核

- [ ] **Step 1: 运行 snapshot focused tests**

覆盖 `HDiaryWidgetDataTests`、projector、coordinator、change monitor 和 Widget intent。

- [ ] **Step 2: 构建 App 与 Widget extension**

确认 Widget 不含 CloudKit entitlement，仍只依赖独立 snapshot Store。

- [ ] **Step 3: 运行完整 HDiary test plan**

Expected: 0 failures；按实际结果报告 discovered、passed、skipped/not-run。

- [ ] **Step 4: 运行态检查**

在模拟器生成主数据，确认 snapshot Store 被创建、Widget 能读取，并确认 snapshot Store URL 与主
Store URL 不同。生产 CloudKit 首次 import 和 134410 消失仍需 TestFlight 真机验收。

- [ ] **Step 5: 独立复审**

检查 Widget 不再访问主 Store、notification adapter 不跨 actor 发送 SwiftData 对象、snapshot
内容上限保持不变，以及 remote/local change 都能触发重建。
