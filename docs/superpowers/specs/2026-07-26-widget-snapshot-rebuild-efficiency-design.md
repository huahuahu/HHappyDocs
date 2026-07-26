# Widget 快照重建效率优化设计

## 背景

当前 Widget snapshot 在 App 启动、主 Store 任意本地保存以及主 Store remote change 后请求重建。
`WidgetSnapshotCoordinator` 会用 350 ms debounce 合并短时间内的连续请求，但每次实际重建仍会：

1. 在 MainActor 上读取全部 Participant 和 Moment。
2. 将全部业务模型转换为 Sendable source values。
3. 排序并投影出“全局最近 8 条与每位 Participant 最近 8 条”的有界并集。
4. 对全部 Participant 重新生成头像缩略图。
5. 遍历 snapshot Store 的全部记录并保存，然后刷新 Widget timeline。

最终 snapshot 的磁盘数据量很小且有明确上限，但同步 fetch、投影以及未变化时的保存和 timeline
刷新会产生不必要的 MainActor 占用与 I/O。本次优化保持现有全量投影语义，不引入增量同步。

## 目标

- 主 Store 的 SwiftData fetch 和业务模型映射不在 MainActor 上执行。
- `ModelContext` 与 SwiftData `@Model` 实例始终留在创建它们的 actor 内。
- Projector 的排序、筛选和并集计算明确运行在 concurrent executor。
- Snapshot 内容未变化时不调用 `ModelContext.save()`，也不刷新 Widget timeline。
- Snapshot 内容变化时继续执行原有 upsert、过期记录删除、保存和 timeline 刷新。
- 保留现有 350 ms debounce、重建期间 dirty 补跑和失败时保留旧快照的语义。

## 不在本次范围内

- 不根据保存的实体或字段过滤 rebuild 请求。
- 不使用 persistent history 解析 CloudKit import 的具体变化。
- 不实现按 Participant 或 Moment 的增量 snapshot 更新。
- 不改变“全局最近 8 条与每位 Participant 最近 8 条的并集”规则。
- 不增加头像摘要、缩略图持久缓存或新的业务模型字段。
- 不改变 Widget snapshot schema、Store URL、CloudKit 配置或 entitlements。

## 方案比较

### 方案 A：专用 reader actor + concurrent projector + no-op write 检测（采用）

用专用 actor 创建和使用主 Store `ModelContext`，返回 Sendable source values；Builder 只负责异步编排；
Projector 使用 `@concurrent`；snapshot writer 比较字段并返回是否真的发生变化。改动边界清晰，不需要
推断 notification 中的业务变化，也不会改变快照正确性。

### 方案 B：为每个 Participant 执行 Top 8 查询

可减少读取的 Moment 数量，但会形成全局查询加每位 Participant 一次查询，并依赖 relationship
predicate 的稳定性。Participant 多时会产生 N+1 查询，本次不采用。

### 方案 C：基于 persistent history 的增量快照

可把读取和写入缩到变更范围，但删除、时间修改和参与者关系修改会同时影响全局及多人 Top 8，
CloudKit import 还需要可靠消费 history token。复杂度和漏更新风险明显高于当前需求，本次不采用。

## 架构与数据流

### Main Store source reader

新增 `MainStoreWidgetSnapshotSourceReader` actor。它持有可跨 actor 的 `ModelContainer`，每次读取时
在 actor 内创建禁用 autosave 的 `ModelContext`，完成 Participant/Moment fetch 与 relationship
prefetch，并在返回前转换成 `WidgetParticipantSource` 和 `WidgetMomentSource`。

新增 Sendable 的 `WidgetSnapshotSourceValue`，包含 Participant 与 Moment source arrays。Reader 不
返回 `ModelContext`、`Participant`、`Moment` 或其他 SwiftData model。

### Builder 与 Projector

`WidgetSnapshotBuilding` 继续由 MainActor coordinator 调用，但 `MainStoreWidgetSnapshotBuilder`
本身只等待 reader 返回 Sendable source values，再调用 Projector。同步 SwiftData fetch 不再占用
MainActor。

`WidgetSnapshotProjector.project(...)` 标记为 `@concurrent`，使排序、删除过滤、全局/每人 Top 8
并集计算明确离开 caller actor。头像缩略图函数继续使用现有 `@concurrent` 实现。

### Snapshot writer

`WidgetSnapshotWriting.replace(with:)` 改为返回 `Bool`：

- 插入、删除或任一持久字段不同，执行赋值和一次 `save()`，返回 `true`。
- 所有 Participant/Moment 字段和集合均相同，不调用 `save()`，返回 `false`。

比较按 UUID 匹配模型，不依赖 snapshot 数组顺序。Participant 比较 `nickName`、
`avatarThumbnailData`；Moment 比较 `timestamp`、`title`，`participantIDs` 按 UUID 集合语义比较，
避免 relationship 返回顺序变化造成无意义保存。插入和删除同样视为变化。

Coordinator 仅在 writer 返回 `true` 后调用 `WidgetCenter.reloadTimelines(ofKind:)`。Build 或写入
失败仍只记录错误并保留旧快照。

## 并发边界

- `ModelContainer` 可以传给 reader actor。
- `ModelContext` 与主业务 `@Model` 实例不离开 reader actor。
- Reader 与 Projector 之间只传递显式 `Sendable` source values。
- Snapshot Store 继续由现有 `WidgetSnapshotStore` actor 串行写入。
- Coordinator 的 debounce、dirty 状态和 WidgetKit 调用继续留在 MainActor。
- 不使用 `@unchecked Sendable`、`Task.detached` 或 GCD 绕过编译器检查。

## 错误处理

- 主 Store fetch 或 source 映射失败：不写 snapshot，不刷新 timeline，保留旧快照。
- Projector 或头像处理返回缺失头像：沿用现有 `nil` fallback，不阻断整个快照。
- Snapshot compare/save 失败：抛回 coordinator，保留旧快照，不刷新 timeline。
- 无变化不是错误；正常返回 `false`。

## 测试策略

实现继续遵循 TDD：先添加失败测试并确认失败原因，再写最小实现。

### Reader actor

- 使用真实 in-memory SwiftData container，验证 reader 能读取并映射 Participant/Moment。
- 验证 `markedAsDelete` 被映射为 source 的 `isDeleted`，relationship 只转换为 UUID。
- 从非 MainActor 测试 actor 调用 reader，编译器保证不跨 actor 传递 ModelContext/model。

### Writer no-op

- 首次写入返回 `true`。
- 写入完全相同的 snapshot 返回 `false`，且数据保持不变。
- `participantIDs` 仅顺序不同而集合相同时返回 `false`。
- 修改 Participant 或 Moment 任一字段返回 `true` 并持久化。
- 增加或移除记录返回 `true`，过期记录被清理。

### Coordinator

- writer 返回 `true` 时刷新一次 timeline。
- writer 返回 `false` 时不刷新 timeline。
- writer 抛错时不刷新并保留既有失败语义。
- debounce 与 rebuild-during-rebuild 测试继续通过。

### 回归验证

- `WidgetSnapshotProjectorTests`、`WidgetSnapshotCoordinatorTests`、`HDiaryWidgetDataTests` 全部通过。
- Widget snapshot 与 Cloud sync diagnostics focused 范围全部通过。
- 完整 HDiary test plan 通过。
- macOS SwiftPM `HDiaryAppFeature` build 继续通过，iOS-only guard 不回退。

## 成功标准

- 主 Store fetch 不再由 MainActor `ModelContext` 执行。
- Projector 明确使用 `@concurrent`。
- 相同 snapshot 的第二次 replace 不保存，coordinator 不刷新 Widget timeline。
- Snapshot 发生任意相关变化时仍正确 upsert、删除、保存并刷新。
- 现有快照内容、数量上限、Widget Store 隔离和 CloudKit 诊断行为不变。
