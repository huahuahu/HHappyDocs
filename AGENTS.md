## Apple Doc

- Prefer the sosumi MCP for Apple Developer Documentation, Human Interface Guidelines, and Apple Developer video transcripts before using web search or direct fetch tools.
- Use non-sosumi sources only when the needed material is not available through sosumi.

## XcodeBuildMcp

- The xcodebuildmcp is installed as a CLI. Prefer it over `xcrun simctl`.
- Project defaults live in `.xcodebuildmcp/config.yaml`.
- At the start of each new agent session, before the first xcodebuildmcp build/run/test call, show active defaults with `session_show_defaults`.
- If active defaults are missing or differ from `.xcodebuildmcp/config.yaml`, read `sessionDefaults` from that file and apply them with `session_set_defaults` before building, running, or testing.
- Resolve any relative `projectPath` in `sessionDefaults` from the repository root before calling `session_set_defaults` (for example, `BirthTracker.xcodeproj` becomes `<repo-root>/BirthTracker.xcodeproj`).
