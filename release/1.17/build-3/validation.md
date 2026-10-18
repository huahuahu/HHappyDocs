# HDiary 1.17（3）验证范围

本次发布包含 PR #70 的宽度驱动媒体分页高度修复。最终实现直接在 ScrollView 上用 onGeometryChange 读取宽度，不使用 Color.clear 或 GeometryReader。

## 修复源码验证

- iPhone 17 Pro / iOS 27.0 与 iPhone Duo / iOS 27.1，各 6 个详情和 6 个媒体快照场景，共 24 个参数场景通过。
- 6 个媒体基准因新的 4/3 高度上限而更新；详情基准、精度阈值保持原值。
- iPhone populated 场景首次快照不匹配，未改基准；定向复跑 6 个详情场景全部通过。MCP 超时后，底层日志确认 TEST EXECUTE SUCCEEDED。
- 最终 Debug App 在专用 iPhone 的运行核验：竖屏图片区域 402×492 pt；横屏图片区域 750×956 pt，媒体父容器 750×1000 pt（另含 44 pt 分页区域），符合宽度 × 4/3；恢复竖屏后回到 402×492 pt。
- 最终版本未重复分页、Quick Look 和 GIF 交互；未通过 TestFlight 真机安装验证。本地截图和模拟器尺寸证据不能替代这些检查。

本地结果包（被忽略的工具工作目录中）：
- Duo：test_sim_2026-10-18T13-16-58-061Z_pid70361_b2c76383.xcresult
- iPhone 媒体：test_sim_2026-10-18T13-24-39-325Z_pid70361_de737081.xcresult
- iPhone 详情复跑：test_sim_2026-10-18T13-27-09-764Z_pid70361_7cc96749.xcresult

此轮 Release 归档、IPA 校验和 ASC 远端回读结果以本目录 status.json 为准。CI 状态单独记录，不将本地通过等同于全部 CI 通过。
