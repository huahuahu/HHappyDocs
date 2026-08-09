# Widget 独立快照设计

## 背景

当前主 App 通过 `HDiaryContainer.iCloudContainer` 打开 App Group 中的 SwiftData
Store，并为该 Store 启用 private CloudKit database。Widget 的
`MomentWidgetUtil.getModelContext()` 则调用 `HDiaryContainer.getCurrentContainer()`，因此
Widget extension 也可能为同一个共享 Store 创建启用了 CloudKit mirroring 的容器。

Apple TN3164 明确指出，App 与 extension 同时为同一个 Store 启动
`NSPersistentCloudKitContainer` mirroring 时，可能触发 `NSCocoaErrorDomain` 134410，导致
CloudKit setup 或 import 中止。TestFlight 真机曾出现首次导入长期不完成以及重复记录，但
目前没有设备日志证明两个症状均由此冲突造成。本次只修复已确认的架构风险，不加入
推测性的去重逻辑。

## 目标

- 只有主 App 打开并同步主 SwiftData Store。
- Widget 永远不打开主 Store，而是读取独立的本地快照 Store。
- 快照数据量有明确上限，不复制正文、媒体或其他 Widget 不使用的数据。
- 主数据发生本地保存或 CloudKit import 后，快照和 Widget timeline 能得到刷新。

## 不采用的方案

### Widget 只读主 Store

可以通过同一 Store URL、`cloudKitDatabase: .none` 和 `allowsSave: false` 避免 Widget
启动第二套 CloudKit mirroring，而且没有数据副本。但 App 与 Widget 仍需跨进程协调同一个
业务 Store，Widget 也会直接依赖完整业务 schema、迁移和数据库可用性。该方案的隔离程度
不符合本次选择。

### 复制完整业务 Store

将完整业务 schema 复制到独立 Store 能复用现有查询代码，但会重复正文、媒体关系、标签和
其他 Widget 不使用的数据，也会让快照迁移继续受完整业务模型影响，因此不采用。

### JSON 或 plist 文件快照

单文件快照实现更轻，但会放弃已经使用的 SwiftData 查询模型，也不符合“给 Widget 一个独立
容器”的设计选择。本次使用轻量 SwiftData Store；如果将来证明跨进程只读该 Store 仍不可靠，
再将存储实现替换为原子文件，而不改变快照的数据边界。

## 总体架构

系统包含两个完全不同的持久化 Store：

1. **主 Store**：保留现有 App Group 路径和 CloudKit 配置，只由主 App 使用。
2. **Widget snapshot Store**：位于 App Group 下单独的明确 URL，只保存 Widget 所需数据，
   `cloudKitDatabase` 固定为 `.none`。

主 App 和 Widget 会分别创建 snapshot Store 的 `ModelContainer` 实例：

- 主 App 使用 `allowsSave: true` 的 writer 配置维护快照。
- Widget extension 使用 `allowsSave: false` 的 reader 配置读取快照。

这两个实例只共同访问 Widget snapshot Store；Widget 不再导入或访问主 Store 的
`ModelContainer`。Snapshot Store 是可丢弃、可重建的派生缓存，不是真实数据来源。

## 模块边界

在 `HDiaryLibrary` 中增加独立的 `HDiaryWidgetData` target，集中放置以下能力：

- Widget snapshot 的 SwiftData schema。
- Snapshot Store URL 和 reader/writer `ModelConfiguration`。
- Snapshot `ModelContainer` 创建接口。
- 与 UIKit、WidgetKit、CloudKit 无关的快照值类型和存储操作。

`HDiaryAppFeature` 依赖 `HDiaryWidgetData`，负责从主 Store 生成快照；
`HDiaryWidgetIntents` 和 `HDiaryWidgetFeature` 依赖 `HDiaryWidgetData`，只负责查询和展示快照。
快照模块不依赖 `HDiaryModel`，避免把主业务模型重新带进 Widget 数据路径。

## 快照模型与数据上限

Snapshot Store 只包含两个轻量模型：

### Participant snapshot

- `uuid`
- `nickName`
- `avatarThumbnailData`

保存全部未删除的 Participant，以保证 Widget 配置中的动态选项完整。头像只保存适合 Widget
18 pt 展示尺寸的缩略图；无头像或缩略失败时保存 `nil`，Widget 使用现有默认头像。不会复制
原始头像数据。

### Moment snapshot

- `uuid`
- `timestamp`
- `title`
- `participantIDs`

不保存正文、评分、媒体、标签、访问统计或完整 SwiftData relationship。已经标记删除的 Moment
不会进入快照。

Widget 当前最多展示 8 条 Moment。快照只保存以下集合的并集，并按 `uuid` 去重：

- 全部 Participant 范围内最近 8 条 Moment。
- 每位 Participant 最近 8 条 Moment。

因此快照规模上限约为“Participant 数量乘以 8，再加全局 8 条”；Moment 同时关联多人时只
存储一份。Snapshot Store 目录标记为不参与设备备份，避免派生数据占用备份空间。

主 Store 生成快照时，Participant 为保证配置选项完整而全量读取；Moment 不全量读取。Reader
执行一次全局最近 8 条有效 Moment 查询，再为每位 Participant 执行一次最近 8 条有效 Moment
查询。所有 Moment 查询都在 Store predicate 中排除 `markedAsDelete`、设置 `fetchLimit`，结果按
UUID 去重。全局查询独立于 Participant 关系，因此没有 Participant 的最近 Moment 仍可进入快照。

该方式以 P+1 次 Moment 查询（P 为 Participant 数量）的 round-trip，换取显式完整 Moment 查询
结果约束在 `8 × (P + 1)` 的范围内。它不使用 `propertiesToFetch`：SwiftData `@Model` 的 partial
fetch 在后续访问所需字段时可能逐对象补查完整行，反而增加查询。这里的上限不承诺
`ModelContext` 内部 relationship fault 或其他 SwiftData 实现细节也严格有界。

## 快照更新流程

主 App 中增加一个串行的 snapshot coordinator，负责以下触发源：

- App 启动并成功打开主 Store。
- 主 Store 的 `ModelContext.didSave`，覆盖本地新增、修改和删除。
- 目标主 Store 的 `NSPersistentStoreRemoteChange`，覆盖 CloudKit import 后的变化。

连续触发会被 debounce 并合并，且任何时间最多执行一次重建。若重建期间又收到变化，当前
重建结束后再执行一次，避免遗漏最后状态。

一次重建按以下顺序执行：

1. `MainStoreWidgetSnapshotSourceReader` actor 独占主 Store fetch：读取全部 Participant，并在
   Store 层读取全局最近 8 条与每位 Participant 最近 8 条有效 Moment，按 UUID 去重后转换为
   Sendable source values。
2. `nonisolated`、`Sendable` 的 `MainStoreWidgetSnapshotBuilder` 通过 `@concurrent build()` 编排，
   对有界 source values 做稳定排序和防御性投影，并生成头像缩略图。
3. 在 snapshot writer context 的一次保存事务中 upsert 目标记录并删除过期记录。
4. 保存成功后调用 `WidgetCenter.reloadTimelines(ofKind:)` 刷新 Moment Widget。

生成或保存失败时保留上一份完整快照，记录错误，但不清空 Store，也不触发 Widget 刷新。
Widget 尚无快照、Store 不存在或 reader 容器创建失败时返回空数据并展示现有占位或空状态，
绝不回退打开主 Store。

## Widget 读取流程

`MomentWidgetUtil` 改为创建 snapshot reader 容器，并提供针对 snapshot 模型的查询。Widget
配置选项从 Participant snapshot 读取；timeline 从 Moment snapshot 读取并按所选
Participant ID 过滤。

Widget reader 配置必须同时满足：

- URL 与主 App 的 snapshot writer URL 相同。
- URL 与主 CloudKit Store URL 不同。
- `cloudKitDatabase == .none`。
- `allowsSave == false`。

Widget target 不再需要 iCloud/CloudKit entitlement；Release 和 Debug entitlements 中相关
声明都会移除，App Group entitlement 保留。

## 远端变化处理

`NSPersistentStoreRemoteChange` 可能来自私有线程。观察器先复制可安全传递的 Store URL 等
值，再切换到主 App 的受控并发域。只有通知 URL 与主 Store URL 一致时才触发快照重建；其他
Store（包括 snapshot Store）的变化会被忽略，避免更新循环。

SwiftData 界面继续通过现有查询和上下文更新展示主 Store 数据。本次不通过重置整个主
`ModelContext` 强行刷新 UI；如果真机日志证明 SwiftData 未合并导入变化，再以独立问题处理
persistent history。成功更新 snapshot 后刷新 Widget timeline。

## 并发与错误处理

- Snapshot coordinator 串行化所有重建请求，避免多个 context 同时修改 snapshot Store。
- Coordinator 的 debounce、dirty 状态和 WidgetKit 调用继续留在 MainActor。
- 主 Store `ModelContext` 与业务 `@Model` 实例只存在于 SourceReader actor；跨 actor 只传显式
  `Sendable` source values。
- `WidgetSnapshotBuilding` 是 `nonisolated`、`Sendable` 协议；生产 Builder 是 `nonisolated`、
  `Sendable` value，`build()` 使用 `@concurrent`，不继承 Coordinator 的 MainActor isolation。
- Notification 回调不直接操作 SwiftData 或 WidgetKit，先进入明确 actor。
- 快照写入失败不会影响主 Store，也不会阻止 CloudKit 后续同步。
- Widget 读取失败返回空结果并记录 `OSLog`，不会 `fatalError`。

## 测试策略

实现遵循 TDD，先添加失败测试并确认失败原因，再编写最小实现。

### 配置测试

- 主 Store URL 与 snapshot Store URL 不同。
- Snapshot reader 与 writer URL 相同。
- Snapshot reader 和 writer 都禁用 CloudKit。
- Snapshot reader 禁止保存，writer 允许保存。
- Widget 不再调用 `HDiaryContainer.getCurrentContainer()`。

### 投影与存储测试

- 只投影 Widget 需要的字段。
- Store 查询阶段排除已经标记删除的 Moment。
- Participant 全量读取，Moment 只读取全局最近 8 条与每位 Participant 最近 8 条。
- 保存全体最近 8 条和每位 Participant 最近 8 条的并集。
- 多人关联的同一个 Moment 只保存一次。
- 无 Participant 的最近 Moment 可由全局查询保留。
- 相同 timestamp 跨过数量上限时，使用 UUID 二级排序稳定截断。
- upsert 更新已有记录并清理过期记录。
- 重建失败时保留上一份快照。
- Widget reader 能读取 writer 保存的数据，但保存操作被拒绝。

### 触发与刷新测试

- App 启动请求初次快照。
- 主 Store 保存请求快照更新。
- 主 Store remote change 请求快照更新。
- 非主 Store remote change 被忽略。
- 多个连续事件被合并。
- 只有 snapshot 保存成功才请求 Widget timeline 刷新。

### 集成验证

- 使用 `xcodebuildmcp` 运行相关 target 测试和完整 HDiary scheme 测试。
- 构建主 App 与 Widget extension，确认移除 Widget CloudKit entitlement 后签名配置有效。
- 在模拟器启动 App，生成主数据后确认 Widget 能读取 snapshot Store。
- 并发启动 App 与 Widget，确认本地日志不出现 134410。

TestFlight 生产 CloudKit 的首次 import 和真机并发启动时不再出现 134410，必须在包含此修复的
TestFlight 构建中完成最终验收。本地和模拟器验证不能替代生产环境检查。

## 数据与资源影响

Snapshot Store 会产生少量本地冗余，但不上传 CloudKit，也不复制正文或媒体。Moment 数量有
明确上限，头像只保留缩略图，Store 还会排除设备备份。相比 Widget 直接读取主 Store，本方案
增加了少量磁盘、投影 CPU 和写入开销，换取主 Store 与 extension 的完整隔离，并降低 Widget
加载完整业务 schema 的内存和迁移成本。

## 不在本次范围内

- 根据症状猜测并删除重复 Moment。
- 为 CloudKit 增加强制同步、轮询或私有 API。
- 将完整主 Store 复制给 Widget。
- 在 App 未运行时让 Widget 自行访问 CloudKit 更新 snapshot。
- 改变现有 CloudKit schema 或生产 container。
- 在没有真机证据时实现额外的 persistent history 合并层。

## 成功标准

- 主 App 是主 Store 唯一的 CloudKit mirroring owner。
- Widget 不打开主 Store，不持有 CloudKit entitlement，也不创建 CloudKit 配置。
- Widget 能从独立、只读的 snapshot Store 展示 Participant 和 Moment。
- Snapshot Moment 数量受设计上限约束，且不包含正文或媒体。
- 本地保存和主 Store remote change 都能触发 snapshot 更新；保存成功后刷新 Widget。
- App 与 Widget 并发运行时不再因同一主 Store 的双重 mirroring 产生 134410。
- 自动化测试覆盖配置、投影、存储、更新触发和 Widget 刷新。
- 重复记录问题不被未经验证的去重逻辑掩盖。
