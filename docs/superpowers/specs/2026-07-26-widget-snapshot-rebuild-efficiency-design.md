# Widget 快照重建效率优化设计

## 背景

最初实现中，Widget snapshot 在 App 启动、主 Store 任意本地保存以及主 Store remote change 后请求重建。
`WidgetSnapshotCoordinator` 会用 350 ms debounce 合并短时间内的连续请求，但每次实际重建仍会：

1. 在 MainActor 上读取全部 Participant 和 Moment。
2. 将全部业务模型转换为 Sendable source values。
3. 排序并投影出“全局最近 8 条与每位 Participant 最近 8 条”的有界并集。
4. 对全部 Participant 重新生成头像缩略图。
5. 遍历 snapshot Store 的全部记录并保存，然后刷新 Widget timeline。

最终 snapshot 的磁盘数据量很小且有明确上限，但同步全量 fetch、投影以及未变化时的保存和
timeline 刷新会产生不必要的 MainActor 占用、完整 Moment 行物化与 I/O。本次优化保持快照的
选择语义，不引入增量同步；主 Store 读取改为 Store 层的有界查询。

## 目标

- 主 Store 的 SwiftData fetch 和业务模型映射不在 MainActor 上执行。
- Participant 仍全部读取；Moment 只读取全局最近 limit 条有效记录与每位 Participant 最近
  limit 条有效记录，并按 UUID 去重。
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

### 方案 A：专用 reader actor + Store 层有界查询 + no-op write 检测（采用）

用专用 actor 创建和使用主 Store `ModelContext`，返回 Sendable source values。Reader 读取全部
Participant，执行一次全局 Top-N 查询和每位 Participant 一次 Top-N 查询；每次 Moment 查询都在
Store predicate 中排除 `markedAsDelete`，按时间倒序、UUID 正序排序并设置 `fetchLimit`，结果按
Moment UUID 去重。全局查询也会保留没有 Participant 的最近 Moment。

这会形成 P+1 次 Moment 查询（P 为 Participant 数量），Participant 很多时会增加查询
round-trip；换取的是本次重建物化的完整 Moment 行数量约束在 `limit × (P + 1)` 的查询结果范围内，
而不是把主 Store 的全部 Moment 都转换为 source values。这个上限只描述显式 Moment fetch 的
结果数量，不承诺 `ModelContext` 内部 relationship fault 或 SwiftData 实现细节都严格有界。

Builder 是 `nonisolated`、`Sendable` value，`build()` 使用 `@concurrent` 编排 reader、Projector
和 thumbnailer；snapshot writer 比较字段并返回是否真的发生变化。改动边界清晰，不需要推断
notification 中的业务变化，也不会改变快照正确性。

### 方案 B：单次查询完成每组 Top-N

理论上可用数据库 window function 或 groupwise Top-N 一次返回全局及每位 Participant 的最近
记录，但 SwiftData 的 `FetchDescriptor` 没有表达这种查询的公开 API，因此不采用。

### 方案 C：基于 persistent history 的增量快照

可把读取和写入缩到变更范围，但删除、时间修改和参与者关系修改会同时影响全局及多人 Top 8，
CloudKit import 还需要可靠消费 history token。复杂度和漏更新风险明显高于当前需求，本次不采用。

## 架构与数据流

### Main Store source reader

新增 `MainStoreWidgetSnapshotSourceReader` actor。它持有可跨 actor 的 `ModelContainer`，每次读取时
在 actor 内创建禁用 autosave 的 `ModelContext`。Reader 全量读取 Participant；Moment 使用一次
全局有界查询和每位 Participant 一次有界查询，均在 Store 层排除 `markedAsDelete`，并预取
`Moment.participants`。各查询结果在映射为 `WidgetMomentSource` 时按 UUID 合并，因此同一 Moment
即使同时出现在全局和多个 Participant 结果中也只返回一次。

不设置 `propertiesToFetch`。对 SwiftData `@Model` 使用 partial fetch 后，再访问未包含字段会让
对象逐个补查完整行；当前映射需要多个 Moment 字段与 participants relationship，这会把表面上的
列裁剪变成额外查询。当前优化只承诺通过 predicate 与 `fetchLimit` 限制显式完整 Moment 查询结果，
不对 context 内部 fault 数量作更强保证。

新增 Sendable 的 `WidgetSnapshotSourceValue`，包含 Participant 与 Moment source arrays。Reader 不
返回 `ModelContext`、`Participant`、`Moment` 或其他 SwiftData model。

### Builder 与 Projector

`WidgetSnapshotBuilding` 是 `nonisolated`、`Sendable` 协议。`WidgetSnapshotCoordinator` 继续在
MainActor 上持有并调用它，但 `MainStoreWidgetSnapshotBuilder` 是 `nonisolated`、`Sendable`
value，`build()` 标记为 `@concurrent`，在 concurrent executor 上等待 reader 返回 Sendable
source values，并继续编排 Projector 和 thumbnailer。同步 SwiftData fetch 只在 reader actor 内执行。

`WidgetSnapshotProjector.project(...)` 标记为 `@concurrent`，继续稳定排序并对 reader 已选择的
全局/每人 Top 8 并集做防御性投影；删除记录已经在 Store 查询阶段排除。头像缩略图函数继续使用
现有 `@concurrent` 实现。

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
- Builder 是 `nonisolated`、`Sendable` value，`build()` 使用 `@concurrent`，不继承 Coordinator 的
  MainActor isolation。
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

- 使用真实 in-memory SwiftData container，验证 reader 读取全部 Participant，但只返回全局 Top-N
  与每位 Participant Top-N 的去重并集。
- 验证 `markedAsDelete` 在 Store 查询阶段被排除，relationship 只转换为 UUID。
- 验证无 Participant 的 Moment 可由全局 Top-N 保留，同一多人 Moment 被多个查询命中时只返回一次。
- 验证 limit 为 0 时仍返回 Participant，但不读取 Moment。
- 验证相同 timestamp 跨过 Top-N 边界时，UUID 二级排序会稳定选择记录。
- 从非 MainActor 测试 actor 调用 reader，编译器保证不跨 actor 传递 ModelContext/model。
- 从非 MainActor 上下文同步创建 Builder 并调用 `build()`，验证其 API 没有重新绑定 MainActor。

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
- Widget snapshot focused 范围全部通过。
- 完整 HDiary test plan 通过。
- macOS SwiftPM `HDiaryAppFeature` build 继续通过，iOS-only guard 不回退。

## 成功标准

- 主 Store fetch 不再由 MainActor `ModelContext` 执行。
- 主 Store Moment 不再全量读取；显式 Moment fetch 使用 P+1 个带 `fetchLimit` 的查询并按 UUID 去重。
- Builder 是 `nonisolated`、`Sendable` value，`build()` 明确使用 `@concurrent`。
- Projector 明确使用 `@concurrent`。
- 相同 snapshot 的第二次 replace 不保存，coordinator 不刷新 Widget timeline。
- Snapshot 发生任意相关变化时仍正确 upsert、删除、保存并刷新。
- 现有快照内容、数量上限和 Widget Store 隔离行为不变。
