# HDiary

HDiary is an iOS app for recording happy moments.

## Project layout

- `HDiary.xcodeproj` — app、widget 和 tests 的根目录 Xcode project。
- `HDiary/` — HDiary app 源码、资源、StoreKit 配置和 app test plan。
- `HDiaryTests/` 和 `HDiaryUITests/` — unit tests 和 UI tests。
- `HDiaryWidget/` — widget extension 源码。
- `HDiaryLibrary/` — HDiary Swift package。
- `HSharedCode/` — `HDiaryLibrary` 使用的 shared Swift package。
- `release/` 和 `IAP-doc/` — release metadata 和 in-app purchase 支持文件。
- `websites/hdiary/` — HDiary website 和 privacy policy。
- `.github/workflows/ios.yml` — GitHub Actions build/test pipeline。
- `scripts/` — 本地 project build/test helper。
