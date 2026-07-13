## Apple Doc

- Prefer the sosumi MCP for Apple Developer Documentation, Human Interface Guidelines, and Apple Developer video transcripts before using web search or direct fetch tools.
- Use non-sosumi sources only when the needed material is not available through sosumi.

## XcodeBuildMcp

- The xcodebuildmcp is installed as a CLI. Prefer it over `xcrun simctl`.
- Project defaults live in `.xcodebuildmcp/config.yaml`.
- At the start of each new agent session, before the first xcodebuildmcp build/run/test call, show active defaults with `session_show_defaults`.
- If active defaults are missing or differ from `.xcodebuildmcp/config.yaml`, read `sessionDefaults` from that file and apply them with `session_set_defaults` before building, running, or testing.
- Resolve any relative `projectPath` in `sessionDefaults` from the repository root before calling `session_set_defaults` (for example, `BirthTracker.xcodeproj` becomes `<repo-root>/BirthTracker.xcodeproj`).


## Simulator in Codex Browser

- When the user asks to view or operate the running iOS app in the Codex in-app browser, use the `ios-simulator-browser` skill together with the in-app browser skill.
- Use the simulator selected by XcodeBuildMCP. Read `sessionDefaults.simulatorId` from `.xcodebuildmcp/config.yaml` when session-default tools are unavailable; do not choose a different booted simulator by name.
- `serve-sim` must run without inherited proxy variables. A proxy-launched process can capture the framebuffer while the browser remains at `Connecting...` or reports `control socket connect timeout`. If the package is not cached yet, fetch/cache it in a separate command using the repository's required full proxy environment, then start the actual mirror offline with all proxy variables removed.
- Start a simulator-scoped, long-running mirror and keep its terminal alive while the browser is using it. Never use an unscoped `serve-sim --kill`:

  ```bash
  SIM="<sessionDefaults.simulatorId>"
  cleanup_serve_sim() {
    env -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY \
      -u http_proxy -u https_proxy -u all_proxy \
      -u NO_PROXY -u no_proxy \
      npx --offline --yes serve-sim@latest --kill "$SIM" >/dev/null 2>&1 || true
  }
  trap cleanup_serve_sim EXIT INT TERM HUP
  cleanup_serve_sim
  env -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY \
    -u http_proxy -u https_proxy -u all_proxy \
    -u NO_PROXY -u no_proxy \
    npx --offline --yes serve-sim@latest "$SIM"
  ```

- Open the exact local URL printed by `serve-sim` (normally `http://localhost:3200`) in the Codex in-app browser. Do not report success until the status is `live`, a real app frame is visible, and one simulator interaction such as switching tabs has visibly changed the app.
- If the in-app browser reports that its webview did not attach, keep the existing browser binding, create a fresh tab, and retry the local URL. Navigation can replace the browser tab ID; if a later action says the tab is missing, list tabs and reacquire the current `Simulator - <device name>` tab instead of restarting the simulator mirror.
- If `serve-sim` shows `Connecting...`, inspect its terminal. Framebuffer/encoder-ready messages prove capture started but not that the control socket is usable. Restart the mirror with the proxy variables removed as above; after it becomes `live`, browser coordinate clicks can operate the streamed simulator UI.

