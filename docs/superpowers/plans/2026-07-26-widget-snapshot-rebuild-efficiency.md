# Widget 快照重建效率优化实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 Widget snapshot 的主 Store 读取和投影移出 MainActor，并在 snapshot 内容未变化时跳过保存与 Widget timeline 刷新。

**Architecture:** `MainStoreWidgetSnapshotSourceReader` actor 独占主 Store 的临时 `ModelContext`，只向 Builder 返回显式 `Sendable` source values；`WidgetSnapshotProjector.project(...)` 使用 `@concurrent` 执行排序和投影。`WidgetSnapshotStore.replace(with:)` 比较持久字段并返回是否发生语义变化，`WidgetSnapshotCoordinator` 只在返回 `true` 时刷新 timeline。

**Tech Stack:** Swift 6.3、SwiftData、Swift Concurrency、WidgetKit、Swift Testing、现有 XCTest 回归测试、XcodeBuildMCP。

## Global Constraints

- 保持 `HDiaryLibrary/Package.swift` 的 `.iOS(.v17)`、`.macOS(.v14)`、Swift 6 language mode、Strict Concurrency 和 `HDiaryAppFeature` 的 `.defaultIsolation(MainActor.self)`。
- 保持现有 snapshot schema、Store URL、`cloudKitDatabase: .none`、reader/writer 配置、Widget entitlements 和 CloudKit diagnostics 不变。
- 保持“全部 Participant、全局最近 8 条 Moment 与每位 Participant 最近 8 条 Moment 的 UUID 去重并集”语义不变。
- 保持 350 ms debounce、重建期间 dirty 补跑、失败时保留旧 snapshot、成功写入后刷新 timeline 的语义。
- 主 Store `ModelContext` 与 `Participant`/`Moment` 等 SwiftData `@Model` 实例不得离开创建它们的 reader actor；跨 actor 只传 `Sendable` value types。
- 不使用 `@unchecked Sendable`、`Task.detached` 或 GCD 绕过 actor 检查。
- 不引入 persistent history、notification 实体过滤、Participant/Moment 增量同步、N+1 Top 8 查询、头像摘要或新业务字段。
- `participantIDs` 变化判断使用 UUID 集合语义；只有顺序不同或重复顺序不同不算内容变化。
- 内容完全相同时不得调用 `ModelContext.save()`，并返回 `false`；插入、删除或任一持久字段变化时保存一次并返回 `true`。
- Coordinator 只有在 writer 返回 `true` 时调用 `WidgetCenter.reloadTimelines(ofKind:)`；build/write 失败与 writer 返回 `false` 都不刷新。
- 新增单元测试使用 Swift Testing；保留并更新现有 XCTest 回归测试，不在本任务迁移旧测试。
- 每个生产行为先写失败测试并观察预期 RED，再写最小实现并观察 GREEN。
- 所有 Xcode build/test 操作使用 XcodeBuildMCP；首次调用前执行 `session_show_defaults`，active defaults 必须为 `/Users/tigerguo/.codex/worktrees/76f2/HHappyDocs/HDiary.xcodeproj`、`HDiary`、`A044BA15-7770-48E6-8E28-E2123A772ACD`。
- 如果 SwiftPM bare repository cache 报 `safe.bareRepository is 'explicit'`，只对失败调用使用 one-shot `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all`，不修改全局 Git 配置。
- 本地验证不得声称已经完成 TestFlight production CloudKit 验收。

---

## 文件结构

- Create `HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/MainStoreWidgetSnapshotSourceReader.swift`：actor 内完成主 Store fetch、relationship prefetch 和业务模型到 source value 的映射。
- Modify `HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/WidgetSnapshotSource.swift`：增加一次读取的 `WidgetSnapshotSourceValue` 聚合值。
- Modify `HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/MainStoreWidgetSnapshotBuilder.swift`：仅编排 reader、projector 和 thumbnailer，不再创建 `ModelContext`。
- Modify `HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/WidgetSnapshotProjector.swift`：为 `project(...)` 增加 `@concurrent`。
- Create `HDiaryLibrary/Tests/HDiaryAppFeatureTests/MainStoreWidgetSnapshotSourceReaderTests.swift`：验证 actor 读取与 source 映射。
- Modify `HDiaryLibrary/Sources/HDiaryWidgetData/Storage/WidgetSnapshotStore.swift`：比较持久字段、跳过 no-op save，并返回 `Bool`。
- Create `HDiaryLibrary/Tests/HDiaryWidgetDataTests/WidgetSnapshotStoreChangeTests.swift`：验证 changed/no-op、集合语义和字段变化。
- Modify `HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/WidgetSnapshotCoordinator.swift`：writer protocol 返回 `Bool`，只在 changed 时刷新。
- Modify `HDiaryLibrary/Tests/HDiaryAppFeatureTests/WidgetSnapshotCoordinatorTests.swift`：现有 writer spies 适配 `Bool` 返回值。
- Modify `HDiaryLibrary/Tests/HDiaryAppFeatureTests/CloudSyncMonitorTests.swift`：现有 runtime writer spy 适配 `Bool` 返回值。
- Create `HDiaryLibrary/Tests/HDiaryAppFeatureTests/WidgetSnapshotCoordinatorChangeTests.swift`：验证 unchanged 不刷新。

---

### Task 0: 固定基线与 XcodeBuildMCP 上下文

**Files:**
- Verify: `.xcodebuildmcp/config.yaml`
- Verify: current worktree and focused snapshot tests

**Interfaces:**
- Produces: 后续 RED/GREEN 可比较的基线，以及本 session 已确认的 XcodeBuildMCP defaults。

- [x] **Step 1: 显示 active defaults**

Call `mcp__xcodebuildmcp__session_show_defaults` with `{}`.

Expected: `projectPath` 为 `/Users/tigerguo/.codex/worktrees/76f2/HHappyDocs/HDiary.xcodeproj`，`scheme` 为 `HDiary`，`simulatorId` 为 `A044BA15-7770-48E6-8E28-E2123A772ACD`。

- [x] **Step 2: 运行 snapshot 基线测试**

Call `mcp__xcodebuildmcp__test_sim` with:

```json
{
  "extraArgs": [
    "-only-testing:HDiaryAppFeatureTests/WidgetSnapshotProjectorTests",
    "-only-testing:HDiaryAppFeatureTests/WidgetSnapshotCoordinatorTests",
    "-only-testing:HDiaryWidgetDataTests/WidgetSnapshotStoreTests"
  ],
  "progress": true
}
```

Expected: 现有 snapshot tests 为 0 failures。若基线失败，先用 `systematic-debugging` 区分既有失败与本任务问题。

---

### Task 1: 用专用 actor 读取主 Store，并显式并发执行投影

**Files:**
- Create: `HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/MainStoreWidgetSnapshotSourceReader.swift`
- Modify: `HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/WidgetSnapshotSource.swift`
- Modify: `HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/MainStoreWidgetSnapshotBuilder.swift`
- Modify: `HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/WidgetSnapshotProjector.swift`
- Create: `HDiaryLibrary/Tests/HDiaryAppFeatureTests/MainStoreWidgetSnapshotSourceReaderTests.swift`
- Regression: `HDiaryLibrary/Tests/HDiaryAppFeatureTests/WidgetSnapshotProjectorTests.swift`

**Interfaces:**
- Produces: `WidgetSnapshotSourceValue(participants:moments:) -> Sendable & Equatable`。
- Produces: `actor MainStoreWidgetSnapshotSourceReader`，初始化为 `init(container: ModelContainer)`，读取接口为 `func read() throws -> WidgetSnapshotSourceValue`。
- Consumes: `WidgetParticipantSource`、`WidgetMomentSource` 和现有 `WidgetAvatarThumbnailer.thumbnailData(...)`。
- Preserves: `MainStoreWidgetSnapshotBuilder(container:)` 和 `WidgetSnapshotBuilding.build()` 的调用接口。

- [ ] **Step 1: 添加 reader actor 的失败测试**

创建 `MainStoreWidgetSnapshotSourceReaderTests.swift`：

```swift
#if os(iOS)

  @testable import HDiaryAppFeature
  import Foundation
  import HDiaryModel
  import SwiftData
  import Testing

  struct MainStoreWidgetSnapshotSourceReaderTests {
    @Test("reader actor 映射主 Store 模型为 Sendable source values")
    func mapsParticipantsMomentsDeletionAndRelationships() async throws {
      let fixture = try makeFixture()
      let reader = MainStoreWidgetSnapshotSourceReader(container: fixture.container)

      let source = try await reader.read()

      #expect(source.participants == [
        WidgetParticipantSource(
          uuid: fixture.participantID,
          nickName: "P",
          avatarData: Data([1, 2, 3])
        ),
      ])
      #expect(source.moments.first { $0.uuid == fixture.activeMomentID } == WidgetMomentSource(
        uuid: fixture.activeMomentID,
        timestamp: Date(timeIntervalSince1970: 1_000),
        title: "Active",
        participantIDs: [fixture.participantID],
        isDeleted: false
      ))
      #expect(source.moments.first { $0.uuid == fixture.deletedMomentID }?.isDeleted == true)
    }

    private func makeFixture() throws -> (
      container: ModelContainer,
      participantID: UUID,
      activeMomentID: UUID,
      deletedMomentID: UUID
    ) {
      let schema = Schema([Tag.self, Moment.self, MediaItem.self, HappyImage.self, Participant.self])
      let configuration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: true,
        cloudKitDatabase: .none
      )
      let container = try ModelContainer(for: schema, configurations: [configuration])
      let context = ModelContext(container)
      context.autosaveEnabled = false
      let participant = Participant.create(
        name: "Participant",
        nickName: "P",
        avatar: Data([1, 2, 3])
      )
      let activeMoment = Moment.create(timestamp: Date(timeIntervalSince1970: 1_000))
      activeMoment.updateTitle("Active")
      activeMoment.updateParticipants([participant])
      let deletedMoment = Moment.create(timestamp: Date(timeIntervalSince1970: 2_000))
      deletedMoment.updateTitle("Deleted")
      deletedMoment.updateParticipants([participant])
      deletedMoment.markAsDelete()
      context.insert(participant)
      context.insert(activeMoment)
      context.insert(deletedMoment)
      try context.save()
      return (container, participant.uuid, activeMoment.uuid, deletedMoment.uuid)
    }
  }

#endif
```

若实际 `Participant` avatar API 名称不同，只在 fixture 中使用模型已存在的公开 API；不得为测试增加生产 API。

- [ ] **Step 2: 运行 reader test 并确认 RED**

Call `mcp__xcodebuildmcp__test_sim` with:

```json
{
  "extraArgs": [
    "-only-testing:HDiaryAppFeatureTests/MainStoreWidgetSnapshotSourceReaderTests"
  ],
  "progress": true
}
```

Expected: FAIL，编译错误明确包含 `cannot find 'MainStoreWidgetSnapshotSourceReader' in scope` 或缺少 `WidgetSnapshotSourceValue`；不能是 fixture 拼写错误。

- [ ] **Step 3: 实现 source 聚合值和 reader actor**

在 `WidgetSnapshotSource.swift` 增加：

```swift
// swiftformat:disable:next redundantSendable
nonisolated struct WidgetSnapshotSourceValue: Sendable, Equatable {
  let participants: [WidgetParticipantSource]
  let moments: [WidgetMomentSource]
}
```

创建 `MainStoreWidgetSnapshotSourceReader.swift`：

```swift
#if os(iOS)

  import HDiaryModel
  import SwiftData

  actor MainStoreWidgetSnapshotSourceReader {
    private let container: ModelContainer

    init(container: ModelContainer) {
      self.container = container
    }

    func read() throws -> WidgetSnapshotSourceValue {
      let context = ModelContext(container)
      context.autosaveEnabled = false

      let participants = try context.fetch(FetchDescriptor<Participant>())
      var momentDescriptor = FetchDescriptor<Moment>(
        sortBy: [SortDescriptor(\Moment.timestamp, order: .reverse)]
      )
      momentDescriptor.relationshipKeyPathsForPrefetching = [\Moment.participants]
      let moments = try context.fetch(momentDescriptor)

      return WidgetSnapshotSourceValue(
        participants: participants.map {
          WidgetParticipantSource(uuid: $0.uuid, nickName: $0.nickName, avatarData: $0.avatar)
        },
        moments: moments.map {
          WidgetMomentSource(
            uuid: $0.uuid,
            timestamp: $0.timestamp,
            title: $0.title,
            participantIDs: ($0.participants ?? []).map(\.uuid),
            isDeleted: $0.markedAsDelete
          )
        }
      )
    }
  }

#endif
```

`ModelContext`、`Participant` 和 `Moment` 只存在于 `read()` 内，返回值不得包含任何 SwiftData model。

- [ ] **Step 4: 把 Builder 改为只编排 reader 和 projector**

将 `MainStoreWidgetSnapshotBuilder` 的 `container` 替换为 reader：

```swift
@MainActor
struct MainStoreWidgetSnapshotBuilder: WidgetSnapshotBuilding {
  private let sourceReader: MainStoreWidgetSnapshotSourceReader

  init(container: ModelContainer) {
    sourceReader = MainStoreWidgetSnapshotSourceReader(container: container)
  }

  func build() async throws -> WidgetSnapshotValue {
    let source = try await sourceReader.read()
    return await WidgetSnapshotProjector.project(
      participants: source.participants,
      moments: source.moments,
      limit: 8,
      thumbnail: {
        await WidgetAvatarThumbnailer.thumbnailData(from: $0, maxPixelSize: 64)
      }
    )
  }
}
```

移除 Builder 中已不再使用的 `HDiaryModel` fetch 逻辑；保留 `SwiftData` import 供 `ModelContainer` 使用。

- [ ] **Step 5: 运行 reader 与既有 Builder tests 并确认 GREEN**

Call `mcp__xcodebuildmcp__test_sim` with:

```json
{
  "extraArgs": [
    "-only-testing:HDiaryAppFeatureTests/MainStoreWidgetSnapshotSourceReaderTests",
    "-only-testing:HDiaryAppFeatureTests/WidgetSnapshotProjectorTests/testBuilderMapsMarkedAsDeleteToDeletedSourceSemantics"
  ],
  "progress": true
}
```

Expected: reader mapping test 与既有 Builder regression test 均通过。

- [ ] **Step 6: 为 projector 增加 `@concurrent` 并验证严格并发编译**

Swift executor 不等同于固定线程，因此不增加 `Thread.isMainThread`、耗时或线程 ID 测试。该一行隔离声明通过 Swift 6 strict-concurrency 的 iOS target 编译、所有参数/返回值的 `Sendable` 检查和既有 projector 业务回归测试验证。

```swift
@concurrent
static func project(
  participants: [WidgetParticipantSource],
  moments: [WidgetMomentSource],
  limit: Int,
  thumbnail: @Sendable (Data?) async -> Data?
) async -> WidgetSnapshotValue {
  // 仅增加上方 @concurrent；函数体不做业务改动。
}
```

Call `mcp__xcodebuildmcp__test_sim` with only `HDiaryAppFeatureTests/WidgetSnapshotProjectorTests`。Expected: iOS target 严格并发编译成功，projector tests 全部通过，snapshot 选择、排序、删除过滤和头像结果不变。

- [ ] **Step 7: 提交 Task 1**

```bash
git add HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot \
  HDiaryLibrary/Tests/HDiaryAppFeatureTests/MainStoreWidgetSnapshotSourceReaderTests.swift
git commit -m "Move widget snapshot projection off main actor"
```

---

### Task 2: 检测 snapshot no-op 并返回变化状态

**Files:**
- Modify: `HDiaryLibrary/Sources/HDiaryWidgetData/Storage/WidgetSnapshotStore.swift`
- Modify: `HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/WidgetSnapshotCoordinator.swift`
- Modify: `HDiaryLibrary/Tests/HDiaryAppFeatureTests/WidgetSnapshotCoordinatorTests.swift`
- Modify: `HDiaryLibrary/Tests/HDiaryAppFeatureTests/CloudSyncMonitorTests.swift`
- Create: `HDiaryLibrary/Tests/HDiaryWidgetDataTests/WidgetSnapshotStoreChangeTests.swift`
- Regression: `HDiaryLibrary/Tests/HDiaryWidgetDataTests/WidgetSnapshotStoreTests.swift`

**Interfaces:**
- Changes: `WidgetSnapshotStore.replace(with:)` 从 `throws -> Void` 改为 `@discardableResult public func replace(with:) throws -> Bool`。
- Changes: `WidgetSnapshotWriting.replace(with:)` 从 `async throws -> Void` 改为 `async throws -> Bool`。
- Preserves: 所有不关心结果的现有调用方可继续忽略 `@discardableResult`。
- Produces: `true` 代表本次确实保存了插入、删除或字段变化；`false` 代表没有调用 `save()`。

- [ ] **Step 1: 添加 changed/no-op 的失败测试**

创建 `WidgetSnapshotStoreChangeTests.swift`，使用真实 in-memory writer container：

```swift
import Foundation
import SwiftData
@testable import HDiaryWidgetData
import Testing

struct WidgetSnapshotStoreChangeTests {
  @Test("首次 replace 报告变化，相同内容的第二次 replace 报告 no-op")
  func reportsChangedThenUnchanged() async throws {
    let store = try makeStore()
    let snapshot = WidgetSnapshotValue(
      participants: [participant(id: 1, name: "Tiger")],
      moments: [moment(id: 1, title: "Moment", participantIDs: [fixedUUID(1)])]
    )

    let firstChanged = try await store.replace(with: snapshot)
    let secondChanged = try await store.replace(with: snapshot)

    #expect(firstChanged)
    #expect(!secondChanged)
    #expect(try await store.snapshot() == snapshot)
  }

  private func makeStore() throws -> WidgetSnapshotStore {
    let schema = Schema([WidgetParticipantSnapshot.self, WidgetMomentSnapshot.self])
    let configuration = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: true,
      cloudKitDatabase: .none
    )
    return WidgetSnapshotStore(
      modelContainer: try ModelContainer(for: schema, configurations: [configuration])
    )
  }

  private func fixedUUID(_ value: Int) -> UUID {
    UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", value))!
  }

  private func participant(id: Int, name: String) -> WidgetParticipantValue {
    WidgetParticipantValue(uuid: fixedUUID(id), nickName: name, avatarThumbnailData: nil)
  }

  private func moment(
    id: Int,
    title: String,
    participantIDs: [UUID]
  ) -> WidgetMomentValue {
    WidgetMomentValue(
      uuid: fixedUUID(1_000 + id),
      timestamp: Date(timeIntervalSince1970: TimeInterval(id)),
      title: title,
      participantIDs: participantIDs
    )
  }
}
```

- [ ] **Step 2: 运行 store change test 并确认 RED**

Call `mcp__xcodebuildmcp__test_sim` with only `HDiaryWidgetDataTests/WidgetSnapshotStoreChangeTests`.

Expected: FAIL，编译错误表明 `replace(with:)` 当前返回 `Void`，不能赋给 `Bool` 断言。

- [ ] **Step 3: 实现字段级 change detection 和 no-op return**

在 `WidgetSnapshotStore.replace(with:)` 内：

```swift
@discardableResult
public func replace(with snapshot: WidgetSnapshotValue) throws -> Bool {
  let context = ModelContext(modelContainer)
  context.autosaveEnabled = false
  var hasChanges = false

  let existingParticipants = try context.fetch(FetchDescriptor<WidgetParticipantSnapshot>())
  let participantsByID = Dictionary(
    uniqueKeysWithValues: existingParticipants.map { ($0.uuid, $0) }
  )
  let desiredParticipantIDs = Set(snapshot.participants.map(\.uuid))

  for value in snapshot.participants {
    if let model = participantsByID[value.uuid] {
      if model.nickName != value.nickName {
        model.nickName = value.nickName
        hasChanges = true
      }
      if model.avatarThumbnailData != value.avatarThumbnailData {
        model.avatarThumbnailData = value.avatarThumbnailData
        hasChanges = true
      }
    } else {
      context.insert(WidgetParticipantSnapshot(
        uuid: value.uuid,
        nickName: value.nickName,
        avatarThumbnailData: value.avatarThumbnailData
      ))
      hasChanges = true
    }
  }

  for model in existingParticipants where !desiredParticipantIDs.contains(model.uuid) {
    context.delete(model)
    hasChanges = true
  }

  let existingMoments = try context.fetch(FetchDescriptor<WidgetMomentSnapshot>())
  let momentsByID = Dictionary(uniqueKeysWithValues: existingMoments.map { ($0.uuid, $0) })
  let desiredMomentIDs = Set(snapshot.moments.map(\.uuid))

  for value in snapshot.moments {
    if let model = momentsByID[value.uuid] {
      if model.timestamp != value.timestamp {
        model.timestamp = value.timestamp
        hasChanges = true
      }
      if model.title != value.title {
        model.title = value.title
        hasChanges = true
      }
      if model.participantIDs != value.participantIDs {
        model.participantIDs = value.participantIDs
        hasChanges = true
      }
    } else {
      context.insert(WidgetMomentSnapshot(
        uuid: value.uuid,
        timestamp: value.timestamp,
        title: value.title,
        participantIDs: value.participantIDs
      ))
      hasChanges = true
    }
  }

  for model in existingMoments where !desiredMomentIDs.contains(model.uuid) {
    context.delete(model)
    hasChanges = true
  }

  guard hasChanges else {
    return false
  }
  try context.save()
  return true
}
```

- [ ] **Step 4: 适配 writer protocol 和现有 spies，但暂不改变刷新条件**

在 `WidgetSnapshotCoordinator.swift`：

```swift
protocol WidgetSnapshotWriting: Sendable {
  func replace(with snapshot: WidgetSnapshotValue) async throws -> Bool
}
```

Coordinator 本步骤仍可暂时忽略返回值：

```swift
_ = try await writer.replace(with: snapshot)
reloadTimeline()
```

将 `WidgetSnapshotCoordinatorTests.swift` 的 `WriterSpy` 改为在既有错误检查与记录后返回 `true`：

```swift
func replace(with snapshot: WidgetSnapshotValue) throws -> Bool {
  if let error {
    throw error
  }
  snapshots.append(snapshot)
  return true
}
```

`PausingWriterSpy` 保留 continuation、并发计数和 `snapshots.append(snapshot)`，在 append 后返回 `true`；`CloudSyncMonitorTests.swift` 的 `RuntimeWriter` 使用：

```swift
func replace(with _: WidgetSnapshotValue) -> Bool {
  replaceCount += 1
  return true
}
```

- [ ] **Step 5: 运行 store change test 并确认 GREEN**

重新运行 `WidgetSnapshotStoreChangeTests` 与 `WidgetSnapshotStoreTests`。Expected: 首次 replace 返回 `true`、完全相同的第二次返回 `false`，原有 upsert/delete 与只读失败测试继续通过。此时 Moment 的最小实现暂按数组比较，下一步用独立 RED 驱动集合语义。

- [ ] **Step 6: 添加 participantIDs 集合语义的失败测试**

在 `WidgetSnapshotStoreChangeTests` 增加：

```swift
@Test("participantIDs 只有顺序不同不触发保存")
func participantOrderIsNotAChange() async throws {
  let store = try makeStore()
  let first = WidgetSnapshotValue(
    participants: [],
    moments: [moment(id: 1, title: "Moment", participantIDs: [fixedUUID(1), fixedUUID(2)])]
  )
  let reordered = WidgetSnapshotValue(
    participants: [],
    moments: [moment(id: 1, title: "Moment", participantIDs: [fixedUUID(2), fixedUUID(1)])]
  )

  #expect(try await store.replace(with: first))
  let changed = try await store.replace(with: reordered)
  let persisted = try await store.snapshot()

  #expect(!changed)
  #expect(Set(persisted.moments.first?.participantIDs ?? []) == Set([fixedUUID(1), fixedUUID(2)]))
}
```

先运行并观察 FAIL（`changed == true`），确认数组顺序触发了无意义变化。随后只把 Moment 的 comparison 改为：

```swift
if Set(model.participantIDs) != Set(value.participantIDs) {
  model.participantIDs = value.participantIDs
  hasChanges = true
}
```

重新运行同一测试并观察 GREEN。

- [ ] **Step 7: 添加字段变化与插入/删除回归测试**

增加两个测试：

```swift
@Test("Participant 或 Moment 持久字段变化会保存并返回 true")
func persistedFieldChangesAreReported() async throws {
  let store = try makeStore()
  let first = WidgetSnapshotValue(
    participants: [participant(id: 1, name: "Old")],
    moments: [moment(id: 1, title: "Old", participantIDs: [fixedUUID(1)])]
  )
  let updated = WidgetSnapshotValue(
    participants: [participant(id: 1, name: "New")],
    moments: [moment(id: 1, title: "New", participantIDs: [fixedUUID(2)])]
  )

  _ = try await store.replace(with: first)
  #expect(try await store.replace(with: updated))
  #expect(try await store.snapshot() == updated)
}

@Test("增加或移除记录会保存并清理过期记录")
func insertionsAndDeletionsAreReported() async throws {
  let store = try makeStore()
  let first = WidgetSnapshotValue(
    participants: [participant(id: 1, name: "Keep"), participant(id: 2, name: "Delete")],
    moments: [moment(id: 1, title: "Delete", participantIDs: [])]
  )
  let second = WidgetSnapshotValue(
    participants: [participant(id: 1, name: "Keep")],
    moments: [moment(id: 2, title: "Insert", participantIDs: [])]
  )

  _ = try await store.replace(with: first)
  #expect(try await store.replace(with: second))
  #expect(try await store.snapshot() == second)
}
```

运行完整 `HDiaryWidgetDataTests`。Expected: 所有 change/no-op 与既有 Store tests 通过。

- [ ] **Step 8: 提交 Task 2**

```bash
git add HDiaryLibrary/Sources/HDiaryWidgetData/Storage/WidgetSnapshotStore.swift \
  HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/WidgetSnapshotCoordinator.swift \
  HDiaryLibrary/Tests/HDiaryWidgetDataTests/WidgetSnapshotStoreChangeTests.swift \
  HDiaryLibrary/Tests/HDiaryAppFeatureTests/WidgetSnapshotCoordinatorTests.swift \
  HDiaryLibrary/Tests/HDiaryAppFeatureTests/CloudSyncMonitorTests.swift
git commit -m "Skip unchanged widget snapshot saves"
```

---

### Task 3: 只有 snapshot 变化时刷新 Widget timeline

**Files:**
- Modify: `HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/WidgetSnapshotCoordinator.swift`
- Create: `HDiaryLibrary/Tests/HDiaryAppFeatureTests/WidgetSnapshotCoordinatorChangeTests.swift`
- Regression: `HDiaryLibrary/Tests/HDiaryAppFeatureTests/WidgetSnapshotCoordinatorTests.swift`

**Interfaces:**
- Consumes: `WidgetSnapshotWriting.replace(with:) async throws -> Bool`。
- Produces: writer 返回 `true` 时刷新一次，返回 `false` 或抛错时不刷新。

- [ ] **Step 1: 添加 unchanged 不刷新的失败测试**

创建 `WidgetSnapshotCoordinatorChangeTests.swift`：

```swift
#if os(iOS)

  @testable import HDiaryAppFeature
  import HDiaryWidgetData
  import Testing

  @MainActor
  struct WidgetSnapshotCoordinatorChangeTests {
    @Test("writer 报告 no-op 时不刷新 timeline")
    func unchangedSnapshotDoesNotReloadTimeline() async {
      let reloader = ReloaderSpy()
      let coordinator = WidgetSnapshotCoordinator(
        builder: BuilderStub(),
        writer: WriterStub(didChange: false),
        sleep: {},
        reloadTimeline: reloader.reload
      )

      await coordinator.rebuildNow()

      #expect(reloader.reloadCount == 0)
    }
  }

  @MainActor
  private struct BuilderStub: WidgetSnapshotBuilding {
    func build() -> WidgetSnapshotValue {
      WidgetSnapshotValue(participants: [], moments: [])
    }
  }

  private actor WriterStub: WidgetSnapshotWriting {
    let didChange: Bool

    init(didChange: Bool) {
      self.didChange = didChange
    }

    func replace(with _: WidgetSnapshotValue) -> Bool {
      didChange
    }
  }

  @MainActor
  private final class ReloaderSpy {
    private(set) var reloadCount = 0

    func reload() {
      reloadCount += 1
    }
  }

#endif
```

- [ ] **Step 2: 运行 coordinator change test 并确认 RED**

Call `mcp__xcodebuildmcp__test_sim` with only `HDiaryAppFeatureTests/WidgetSnapshotCoordinatorChangeTests`.

Expected: FAIL，`reloadCount` 实际为 1；说明当前 coordinator 虽拿到 `false` 仍刷新。

- [ ] **Step 3: 实现条件刷新**

将 `rebuildSnapshot()` 改为：

```swift
private func rebuildSnapshot() async {
  do {
    let snapshot = try await builder.build()
    let didChange = try await writer.replace(with: snapshot)
    if didChange {
      reloadTimeline()
    }
  }
  catch {
    Log.data.error("Failed to rebuild widget snapshot: \(error)")
  }
}
```

- [ ] **Step 4: 运行 coordinator tests 并确认 GREEN**

运行 `WidgetSnapshotCoordinatorChangeTests` 和完整 `WidgetSnapshotCoordinatorTests`。Expected:

- unchanged test 的 reload count 为 0；
- changed 成功写入仍刷新一次；
- timeline 仍在 write 完成后才刷新；
- build/write 失败不刷新；
- debounce 合并和 rebuild-during-rebuild 串行补跑仍通过。

- [ ] **Step 5: 提交 Task 3**

```bash
git add HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/WidgetSnapshotCoordinator.swift \
  HDiaryLibrary/Tests/HDiaryAppFeatureTests/WidgetSnapshotCoordinatorChangeTests.swift
git commit -m "Reload widget only for changed snapshots"
```

---

### Task 4: 回归验证、专项审查与交付

**Files:**
- Verify: all files changed since `a1326be`
- Update: `.superpowers/sdd/progress.md` and task report artifacts as required by subagent-driven-development

**Interfaces:**
- Produces: fresh focused/full test evidence、SwiftPM build evidence、并发/SwiftData review 结论与干净提交历史。

- [ ] **Step 1: 运行 snapshot 与 diagnostics focused tests**

Call `mcp__xcodebuildmcp__test_sim` with:

```json
{
  "extraArgs": [
    "-only-testing:HDiaryWidgetDataTests",
    "-only-testing:HDiaryAppFeatureTests/MainStoreWidgetSnapshotSourceReaderTests",
    "-only-testing:HDiaryAppFeatureTests/WidgetSnapshotProjectorTests",
    "-only-testing:HDiaryAppFeatureTests/WidgetSnapshotCoordinatorTests",
    "-only-testing:HDiaryAppFeatureTests/WidgetSnapshotCoordinatorChangeTests",
    "-only-testing:HDiaryAppFeatureTests/CloudSyncDiagnosticsTests",
    "-only-testing:HDiaryAppFeatureTests/CloudSyncMonitorTests",
    "-only-testing:HDiaryAppFeatureTests/MomentWidgetIntentTests"
  ],
  "progress": true
}
```

Expected: 0 failures；报告实际 discovered/passed 数量，不从旧报告推断。

- [ ] **Step 2: 构建 macOS SwiftPM target**

Call `mcp__xcodebuildmcp__swift_package_build` with:

```json
{
  "packagePath": "/Users/tigerguo/.codex/worktrees/76f2/HHappyDocs/HDiaryLibrary",
  "targetName": "HDiaryAppFeature",
  "parseAsLibrary": true
}
```

Expected: build succeeds，确认新增 iOS-only reader/test 文件的 guard 没有破坏 macOS package build。

- [ ] **Step 3: 运行完整 HDiary test plan**

Call `mcp__xcodebuildmcp__test_sim` with `{ "progress": true }`.

Expected: 完整 test plan 0 failures；分别报告 discovered、passed、skipped/not-run 数量，不能把 test plan 外 UI tests 算作失败。

- [ ] **Step 4: 执行静态边界检查**

```bash
rg -n "ModelContext|FetchDescriptor<Participant>|FetchDescriptor<Moment>" \
  HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/MainStoreWidgetSnapshotBuilder.swift
rg -n "@concurrent" \
  HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot/WidgetSnapshotProjector.swift
rg -n "@unchecked Sendable|Task\.detached|DispatchQueue" \
  HDiaryLibrary/Sources/HDiaryAppFeature/WidgetSnapshot \
  HDiaryLibrary/Sources/HDiaryWidgetData/Storage/WidgetSnapshotStore.swift
git diff --check a1326be..HEAD
git status --short --branch
```

Expected: Builder 的主 Store fetch 搜索无输出；Projector 命中 `@concurrent`；禁止模式搜索无输出；`git diff --check` 无错误；只有明确的任务文件发生变化。

- [ ] **Step 5: 独立审查 Swift concurrency、SwiftData 与 spec compliance**

使用 `requesting-code-review` 派发最强可用模型，审查 `a1326be..HEAD`，重点检查：

- `ModelContext`/`@Model` 是否严格留在 reader actor；
- default MainActor isolation 下 source values 与 actor API 是否正确；
- actor reentrancy 是否引入状态假设；
- no-op 路径是否确实在 `save()` 前返回；
- `participantIDs` 是否仅用 Set 语义判断；
- changed、unchanged、throw 三条 coordinator 路径是否分别刷新 1、0、0 次；
- 是否意外改变 snapshot 内容边界、Store/CloudKit 配置或 diagnostics。

Critical/Important findings 必须修复、重跑覆盖测试并重新审查；Minor findings 记录后由最终 reviewer 判断是否应在本任务处理。

- [ ] **Step 6: 提交验证修正并确认交付状态**

若审查没有修正，不创建空 commit。若有修正，只逐个 stage reviewer finding 实际涉及的任务文件，
确认 `git diff --cached --stat` 不含无关改动后提交为
`Address widget snapshot efficiency review`。

最后重新运行受影响的 focused tests、`git diff --check a1326be..HEAD` 和 `git status --short --branch`。交付报告必须明确：本地完成了哪些验证，以及 TestFlight production CloudKit 仍需随包含该实现的构建验收。
