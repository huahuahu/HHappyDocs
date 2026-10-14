# HDiary 新版本发布

项目发布流程由 [hdiary-release 技能](../.agents/skills/hdiary-release/SKILL.md) 维护。它覆盖 bump version/build、App Store 截图、Release 签名打包、TestFlight、正式提审、手动发布和 Git tag。

在本项目中调用：

```text
使用 $hdiary-release 为 HDiary 准备新版本，更新截图，打包并分发 TestFlight，
完成 App Store 提审，确认审核通过后手动发布，并处理发布 tag。
```

只做部分流程时明确范围，例如“只检查发布准备度”“只发 TestFlight”或“仅准备资料，暂不提审”。

新版本按“本地资料和截图准备 → 创建或复用 MANUAL 版本及 localizations → 上传截图 → 绑定 build、完整校验 → 提审”的依赖顺序推进。继续已有 TestFlight 发布时，复用与目标版本和源码匹配的有效 build，跳过版本/build 递增、归档、导出和重复上传；仅 TestFlight 请求不创建正式 App Store 版本。

- [版本号、build 号与 tag 规则](../.agents/skills/hdiary-release/references/version-and-tags.md)
- [真实截图、合成、上传和远端核验](../.agents/skills/hdiary-release/references/screenshots.md)
- [打包、TestFlight、提审和手动发布](../.agents/skills/hdiary-release/references/distribution.md)

新发布的默认策略为 **MANUAL**：提审前设置并回读，提审后再次确认；审核通过后等待手动上线指令。`release/1.16/` 中的自动发布策略只代表历史快照，不是新版本默认值。

每次发布的资料和核验结果存放在 `release/<version>/`。正式 `v<version>` tag 默认在最终 build 审核通过、源码固定后创建；提审时尚未满足条件则在发布记录中写明暂缓原因。tag 不代表已经上线。
