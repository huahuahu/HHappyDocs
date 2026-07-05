# Swift Package Shell Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把第一批非 UI 启动逻辑和 deep link 规则迁入 `HDiaryLibrary` 的 `HDiaryServices` target，并让 app target 只负责 root 壳层调用。

**Architecture:** 新增 `HDiaryServices` Swift Package product，依赖 `HDiaryModel` 和 `HDiaryConstants`，承载启动数据维护 service 与 deep link 规则。`HDiary` app target 通过 Xcode project 引入 `HDiaryServices`，root view 只负责展示 tab，启动副作用移动到 app 壳层 `AppRootView`。

**Tech Stack:** Swift 5.9、SwiftPM、SwiftData、SwiftUI、XCTest、XcodeBuildMCP、Xcode project file synchronization。

## Global Constraints

- 保留 `HDiary.xcodeproj`；它继续负责 capabilities、entitlements、embedded extension、scheme、target graph 和 package product wiring。
- 不新建 `HDiaryFeatures` package，也不把 HDiary 代码拆成多个 package；第一期只在 `HDiaryLibrary` 内新增 `HDiaryServices` target。
- 不迁移或重写 SwiftData schema、CloudKit identifier、app group 或持久化路径。
- 不改变 widget 的 WidgetKit entry、timeline provider 壳层和 extension 专属配置。
- Package targets 不 import `HDiary` app target，也不依赖 app target 中的 global environment。
- 每个迁移步骤只改变代码归属或调用位置，不改变用户数据语义。
- XcodeBuildMCP build/test/run 调用前先运行 `xcodebuildmcp-session_show_defaults`；如果 defaults 未使用仓库根目录 `HDiary.xcodeproj`，按 `.xcodebuildmcp/config.yaml` 设置绝对路径 defaults 后再 build/test。
- 如果 SwiftPM 或 xcodebuild 解析 package 时失败并出现 `fatal: cannot use bare repository ... safe.bareRepository is 'explicit'`，用一次性前缀重试：`GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all <command>`。
- 不修改 signing、bundle id、CloudKit、app group、Info.plist、entitlements 或 scheme 名称。

---

## File Structure

- Modify: `HDiaryLibrary/Package.swift`
  - 增加 `HDiaryServices` product、target 和 `HDiaryServicesTests` test target。
- Move: `HDiaryLibrary/Sources/HDiaryModel/ModelOperation/StartupDataMaintenanceService.swift`
  - To: `HDiaryLibrary/Sources/HDiaryServices/StartupDataMaintenanceService.swift`
  - 继续暴露 `StartupDataMaintenanceService`，但它不再属于 `HDiaryModel` target。
- Move: `HDiaryLibrary/Tests/HDiaryModelTests/StartupDataMaintenanceServiceTests.swift`
  - To: `HDiaryLibrary/Tests/HDiaryServicesTests/StartupDataMaintenanceServiceTests.swift`
  - 改为测试 `HDiaryServices`。
- Create: `HDiaryLibrary/Sources/HDiaryServices/DeepLink.swift`
  - 暴露 HDiary deep link scheme、host、moment target 和 add moment URL 构造逻辑。
- Create: `HDiaryLibrary/Tests/HDiaryServicesTests/DeepLinkTests.swift`
  - 验证 deep link URL 构造规则稳定。
- Modify: `HDiary.xcodeproj/project.pbxproj`
  - 将 `HDiaryServices` package product wired 到 `HDiary` app target。
- Modify: `HDiary/BaseTabView.swift`
  - 移除启动维护副作用，保留 tab composition、search 状态和 tab item。
- Create: `HDiary/Common/Bootstrap/AppRootView.swift`
  - 作为 app 壳层 root，负责调用 package service 和设置 `ModelContext.undoManager`。
- Modify: `HDiary/HDiaryApp.swift`
  - 从 `BaseTabView` 切到 `AppRootView`。
- Modify: `HDiary/Common/Navigation/UrlHandler.swift`
  - 使用 package 中的 `DeepLink`，移除 app target 内重复定义。
- Modify: `HDiary/Common/Notification/LocalNotificationManager.swift`
  - 使用 package 中的 `DeepLink` 构造 add moment URL。
- Modify: `HDiaryTests/HDiaryTests.swift`
  - 删除模板测试，增加 `AppRootView` 构造测试，防止 root 壳入口丢失。

---

### Task 0: Restore SwiftPM baseline by declaring the current macOS platform

**Files:**
- Modify: `HDiaryLibrary/Package.swift`
- Modify: `HSharedCode/Package.swift`
- Modify: `HDiaryLibrary/Sources/HDiaryConstants/AppConstants/AppConstants.swift`
- Modify: `HDiaryLibrary/Sources/HDiaryModel/Model/Participant.swift`
- Modify: `HDiaryLibrary/Sources/HDiaryModel/Model/MediaItem.swift`

**Interfaces:**
- Consumes:
  - Swift Package platform declaration in `HDiaryLibrary/Package.swift`
  - Swift Package platform declaration in `HSharedCode/Package.swift`
  - Xcode 26.6 / Swift 6.3.3 support for macOS 26.0 string platform versions
- Produces:
  - `HDiaryLibrary` and `HSharedCode` declare `.macOS("26.0")`.
  - `AppConstants.groupName` and `UserDefaults.hDiaryShared` are available to macOS SwiftPM compilation.
  - `UserPreferences` can compile on macOS SwiftPM hosts without changing its iOS runtime behavior.
  - `Participant`, `MediaItem`, and `HappyImage` model storage compile on macOS while UIKit-only image helpers remain available on iOS.

- [ ] **Step 1: Verify the baseline failure**

Run:

```bash
GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 swift test --package-path HDiaryLibrary
```

Expected: FAIL with errors from `HDiaryLibrary/Sources/HDiaryConstants/UserDefaults/UserPreferences.swift` mentioning `ObservationIgnored()` / `ObservationRegistrar` macOS availability or `UserDefaults?.hDiaryShared` missing.

- [ ] **Step 2: Raise Swift Package macOS platform declarations**

In `HDiaryLibrary/Package.swift`, replace:

```swift
  platforms: [.iOS(.v17), .macOS(.v13)],
```

with:

```swift
  platforms: [.iOS(.v17), .macOS("26.0")],
```

In `HSharedCode/Package.swift`, replace:

```swift
  platforms: [.iOS(.v17), .macOS(.v13)],
```

with:

```swift
  platforms: [.iOS(.v17), .macOS("26.0")],
```

- [ ] **Step 3: Make shared app group defaults compile on macOS**

In `HDiaryLibrary/Sources/HDiaryConstants/AppConstants/AppConstants.swift`, move the `Foundation` import, `AppConstants.groupName`, `AppConstants.cloudKitContainerIdentifier`, and `UserDefaults.hDiaryShared` outside the iOS-only guard while keeping app runtime-only values under `#if os(iOS)`. The resulting file must be:

```swift
//
//  AppConstants.swift
//  HDiary
//
//  Created by tigerguo on 2023/7/13.
//

import Foundation

public enum AppConstants {
  public static let groupName = "group.com.tiger.suzhou.HDiary"
  public static let cloudKitContainerIdentifier = "iCloud.com.tigerhuahuahu.suzhou.hdiary"

  #if os(iOS)
    public static let appName = String(localized: "CFBundleDisplayName", table: "InfoPlist")
    public static let privacyUrl = "https://app.tigerpro.org/hdiary/privacy.html"

    public static let groupContainerURL: URL = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: Self.groupName)!
  #endif
}

#if os(iOS)

  public extension AppConstants {
    enum IAP {
      public static let freeRecordNumber = 50
    }
  }

#endif

public extension UserDefaults {
  static let hDiaryShared = UserDefaults(suiteName: AppConstants.groupName)
}

#if os(iOS)

  public enum HDiaryIntentKind: String {
    case moment = "Moment"
  }

#endif
```

- [ ] **Step 4: Isolate UIKit-only model helpers**

In `HDiaryLibrary/Sources/HDiaryModel/Model/Participant.swift`, replace:

```swift
import UIKit
```

with:

```swift
#if canImport(UIKit)
  import UIKit
#endif
```

Wrap the avatar image helper so only UIKit-capable platforms compile it:

```swift
#if canImport(UIKit)
  public func getAvatarImage() -> UIImage {
    if let avatar {
      return UIImage(data: avatar) ?? UIImage(resource: .defaultPerson)
    }
    else {
      return UIImage(resource: .defaultPerson)
    }
  }
#endif
```

In `HDiaryLibrary/Sources/HDiaryModel/Model/MediaItem.swift`, remove the file-level `#if os(iOS)` / `#endif` wrapper so the model types compile for macOS SwiftPM hosts. Replace the import block with:

```swift
import Foundation
import HDiaryConstants
import SwiftData

#if canImport(UIKit)
  import HMedia
  import UIKit
#endif
```

Keep `MediaItem`, `HappyImage`, and their `Encodable` conformances available on all platforms. Wrap only the UIKit image helpers inside `HappyImage`:

```swift
#if canImport(UIKit)
  public var uiImage: UIImage? {
    UIImage(data: data)
  }

  public func updateThumbnail() {
    if thumbnailData150px == nil {
      thumbnailData150px = try? UIImage.downsample(imageData: data, to: CGSize(width: 150, height: 150))
    }
    if thumbnailData500px == nil {
      thumbnailData500px = try? UIImage.downsample(imageData: data, to: CGSize(width: 500, height: 500))
    }

    if thumbnailData1000px == nil {
      thumbnailData1000px = try? UIImage.downsample(imageData: data, to: CGSize(width: 1000, height: 1000))
    }
  }
#endif
```

- [ ] **Step 5: Verify the package baseline is restored**

Run:

```bash
GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 swift test --package-path HDiaryLibrary
```

Expected: PASS. The output may still contain existing SwiftPM warnings for package resources or upstream package documentation files, but it must not contain compile errors from `UserPreferences.swift`, `Participant.swift`, or `MediaItem.swift`.

- [ ] **Step 6: Commit**

Run:

```bash
git add HDiaryLibrary/Package.swift HSharedCode/Package.swift HDiaryLibrary/Sources/HDiaryConstants/AppConstants/AppConstants.swift HDiaryLibrary/Sources/HDiaryModel/Model/Participant.swift HDiaryLibrary/Sources/HDiaryModel/Model/MediaItem.swift
git commit -m "fix: raise package macos platform" -m "Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 1: Add `HDiaryServices` and move startup maintenance service

**Files:**
- Modify: `HDiaryLibrary/Package.swift`
- Move: `HDiaryLibrary/Sources/HDiaryModel/ModelOperation/StartupDataMaintenanceService.swift` -> `HDiaryLibrary/Sources/HDiaryServices/StartupDataMaintenanceService.swift`
- Move: `HDiaryLibrary/Tests/HDiaryModelTests/StartupDataMaintenanceServiceTests.swift` -> `HDiaryLibrary/Tests/HDiaryServicesTests/StartupDataMaintenanceServiceTests.swift`
- Modify: `HDiaryLibrary/Sources/HDiaryModel/Model/Container/ModelContainer.swift`

**Interfaces:**
- Consumes:
  - `HDiaryModel.Moment`
  - `HDiaryModel.MediaItem`
  - `HDiaryModel.HappyImage`
  - `HDiaryModel.Schema.hDiaryScheme`
  - `HDiaryConstants.Log`
  - `SwiftData.ModelContext`
  - `SwiftData.Schema.hDiaryScheme`
- Produces:
  - `public struct StartupDataMaintenanceService`
  - `public func runLoggingFailures(in modelContext: ModelContext, deletedMomentRetention: TimeInterval = 60 * 60 * 24 * 30)`
  - `public func migrateLegacyImages(in modelContext: ModelContext) throws -> LegacyImageMigrationResult`
  - `public func updateMissingMediaStorageSizes(in modelContext: ModelContext) throws -> MediaStorageUpdateResult`
  - `public func cleanUpOrphanMediaItems(in modelContext: ModelContext) throws -> OrphanMediaCleanupResult`
  - `public func cleanUpDeletedMoments(in modelContext: ModelContext, deleteTimeThreshold: Date) throws -> DeletedMomentCleanupResult`

- [ ] **Step 1: Move the existing tests to the new test target and make them fail**

Run:

```bash
mkdir -p HDiaryLibrary/Tests/HDiaryServicesTests
git mv HDiaryLibrary/Tests/HDiaryModelTests/StartupDataMaintenanceServiceTests.swift HDiaryLibrary/Tests/HDiaryServicesTests/StartupDataMaintenanceServiceTests.swift
```

Replace the import block at the top of `HDiaryLibrary/Tests/HDiaryServicesTests/StartupDataMaintenanceServiceTests.swift` with:

```swift
@testable import HDiaryServices
import HDiaryModel
import SwiftData
import XCTest
```

Remove the trailing `#endif` at the end of `HDiaryLibrary/Tests/HDiaryServicesTests/StartupDataMaintenanceServiceTests.swift`.

Add the `HDiaryServices` product, target, and test target to `HDiaryLibrary/Package.swift`:

```swift
    .library(
      name: "HDiaryServices",
      targets: ["HDiaryServices"]
    ),
```

```swift
    .target(
      name: "HDiaryServices",
      dependencies: [
        "HDiaryConstants",
        "HDiaryModel",
      ]
    ),
    .testTarget(
      name: "HDiaryServicesTests",
      dependencies: [
        "HDiaryServices",
        "HDiaryModel",
      ]
    ),
```

Place the product after `HDiaryIAP` and the target before `HDiarySearch`.

- [ ] **Step 2: Run the moved test to verify it fails**

Run:

```bash
swift test --package-path HDiaryLibrary --filter StartupDataMaintenanceServiceTests
```

Expected: FAIL because `HDiaryServices` has no source files or `StartupDataMaintenanceService` is not defined in that target.

- [ ] **Step 3: Move the startup service into `HDiaryServices`**

Run:

```bash
mkdir -p HDiaryLibrary/Sources/HDiaryServices
git mv HDiaryLibrary/Sources/HDiaryModel/ModelOperation/StartupDataMaintenanceService.swift HDiaryLibrary/Sources/HDiaryServices/StartupDataMaintenanceService.swift
```

Update the import block at the top of `HDiaryLibrary/Sources/HDiaryServices/StartupDataMaintenanceService.swift` to:

```swift
import Foundation
import HDiaryConstants
import HDiaryModel
import SwiftData
```

Remove the trailing `#endif` at the end of `HDiaryLibrary/Sources/HDiaryServices/StartupDataMaintenanceService.swift`.

Inside `migrateLegacyImages(in:)`, keep legacy thumbnail generation on UIKit-capable platforms by changing:

```swift
          image.updateThumbnail()
```

to:

```swift
          #if canImport(UIKit)
            image.updateThumbnail()
          #endif
```

- [ ] **Step 4: Make the SwiftData schema available to package-host tests**

In `HDiaryLibrary/Sources/HDiaryModel/Model/Container/ModelContainer.swift`, move `Schema.hDiaryScheme` outside the iOS-only container guard. The top of the file must become:

```swift
//
//  ICloudContainer.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/17.
//

import Foundation
import SwiftData

extension Schema {
  static let hDiaryScheme = Schema([Tag.self, Moment.self, MediaItem.self, Participant.self])
}

#if os(iOS)

  import HDiaryConstants
```

Keep `HDiaryContainer`, `localContainer`, `iCloudContainer`, and `getCurrentContainer()` inside `#if os(iOS)`.

- [ ] **Step 5: Run package tests to verify the moved service passes**

Run:

```bash
swift test --package-path HDiaryLibrary --filter StartupDataMaintenanceServiceTests
```

Expected: PASS for all `StartupDataMaintenanceServiceTests`; the output must show those tests were executed, not `0 tests`.

- [ ] **Step 6: Run all package tests**

Run:

```bash
swift test --package-path HDiaryLibrary
```

Expected: PASS for `HDiaryConstantsTests`, `HDiaryModelTests`, `HDiarySearchTests`, `HDiaryIAPTests`, and `HDiaryServicesTests`.

- [ ] **Step 7: Commit**

Run:

```bash
git add HDiaryLibrary/Package.swift HDiaryLibrary/Sources/HDiaryServices/StartupDataMaintenanceService.swift HDiaryLibrary/Tests/HDiaryServicesTests/StartupDataMaintenanceServiceTests.swift HDiaryLibrary/Sources/HDiaryModel/Model/Container/ModelContainer.swift
git add -u HDiaryLibrary/Sources/HDiaryModel/ModelOperation/StartupDataMaintenanceService.swift HDiaryLibrary/Tests/HDiaryModelTests/StartupDataMaintenanceServiceTests.swift
git commit -m "refactor: move startup maintenance into services package" -m "Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 2: Move deep link rules into `HDiaryServices`

**Files:**
- Create: `HDiaryLibrary/Sources/HDiaryServices/DeepLink.swift`
- Create: `HDiaryLibrary/Tests/HDiaryServicesTests/DeepLinkTests.swift`

**Interfaces:**
- Consumes: `Foundation.URLComponents`
- Produces:
  - `public enum DeepLink`
  - `public static let scheme: String`
  - `public enum Host: String` with cases `moment`, `library`, `setting`
  - `public enum MomentTarget: String` with case `add`
  - `public static func getAddMomentUrl() -> URL?`

- [ ] **Step 1: Write the failing deep link tests**

Create `HDiaryLibrary/Tests/HDiaryServicesTests/DeepLinkTests.swift`:

```swift
#if os(iOS)

  @testable import HDiaryServices
  import XCTest

  final class DeepLinkTests: XCTestCase {
    func testAddMomentURLUsesStableSchemeHostAndPath() throws {
      let url = try XCTUnwrap(DeepLink.getAddMomentUrl())

      XCTAssertEqual(url.scheme, "hdiarydl")
      XCTAssertEqual(url.host(percentEncoded: false), "moment")
      XCTAssertEqual(url.path(percentEncoded: false), "/add")
      XCTAssertEqual(url.absoluteString, "hdiarydl://moment/add")
    }

    func testMomentHostRawValueMatchesExistingAppRoutes() {
      XCTAssertEqual(DeepLink.Host.moment.rawValue, "moment")
      XCTAssertEqual(DeepLink.Host.library.rawValue, "library")
      XCTAssertEqual(DeepLink.Host.setting.rawValue, "setting")
    }

    func testMomentTargetRawValueMatchesExistingAddRoute() {
      XCTAssertEqual(DeepLink.MomentTarget.add.rawValue, "add")
    }
  }

#endif
```

- [ ] **Step 2: Run the new tests to verify they fail**

Run:

```bash
swift test --package-path HDiaryLibrary --filter DeepLinkTests
```

Expected: FAIL with `cannot find 'DeepLink' in scope`.

- [ ] **Step 3: Implement package deep link rules**

Create `HDiaryLibrary/Sources/HDiaryServices/DeepLink.swift`:

```swift
#if os(iOS)

  import Foundation

  public enum DeepLink {
    public static let scheme = "hdiarydl"

    public enum Host: String, RawRepresentable {
      case moment
      case library
      case setting
    }

    public enum MomentTarget: String, RawRepresentable {
      case add
    }

    public static func getAddMomentUrl() -> URL? {
      var urlComponents = URLComponents()
      urlComponents.scheme = Self.scheme
      urlComponents.host = Self.Host.moment.rawValue
      urlComponents.path = "/\(MomentTarget.add.rawValue)"
      return urlComponents.url
    }
  }

#endif
```

- [ ] **Step 4: Run the deep link tests to verify they pass**

Run:

```bash
swift test --package-path HDiaryLibrary --filter DeepLinkTests
```

Expected: PASS for all `DeepLinkTests`.

- [ ] **Step 5: Run all package tests after adding deep links**

Run:

```bash
swift test --package-path HDiaryLibrary
```

Expected: PASS for `HDiaryConstantsTests`, `HDiaryModelTests`, `HDiarySearchTests`, `HDiaryIAPTests`, `StartupDataMaintenanceServiceTests`, and `DeepLinkTests`.

- [ ] **Step 6: Commit**

Run:

```bash
git add HDiaryLibrary/Sources/HDiaryServices/DeepLink.swift HDiaryLibrary/Tests/HDiaryServicesTests/DeepLinkTests.swift
git commit -m "feat: add hdiary services deep links" -m "Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 3: Wire `HDiaryServices` into the app target

**Files:**
- Modify: `HDiary.xcodeproj/project.pbxproj`
- Modify: `HDiary/BaseTabView.swift`
- Modify: `HDiary/Common/Navigation/UrlHandler.swift`
- Modify: `HDiary/Common/Notification/LocalNotificationManager.swift`

**Interfaces:**
- Consumes:
  - `HDiaryServices.StartupDataMaintenanceService`
  - `HDiaryServices.DeepLink`
- Produces:
  - App target can import `HDiaryServices`.
  - App target no longer defines its own `DeepLink` enum.

- [ ] **Step 1: Add `HDiaryServices` as an app package product dependency**

Edit `HDiary.xcodeproj/project.pbxproj` with these deterministic IDs:

Add to the `PBXBuildFile section` after the `HDiarySearch in Frameworks` entry:

```text
		60F200002E01000100000001 /* HDiaryServices in Frameworks */ = {isa = PBXBuildFile; productRef = 60F200012E01000100000001 /* HDiaryServices */; };
```

Add to the app target `Frameworks` files list after `HDiarySearch in Frameworks`:

```text
				60F200002E01000100000001 /* HDiaryServices in Frameworks */,
```

Add to the app target `packageProductDependencies` list after `HDiarySearch`:

```text
				60F200012E01000100000001 /* HDiaryServices */,
```

Add to the `XCSwiftPackageProductDependency section` after `HDiarySearch`:

```text
		60F200012E01000100000001 /* HDiaryServices */ = {
			isa = XCSwiftPackageProductDependency;
			productName = HDiaryServices;
		};
```

- [ ] **Step 2: Import `HDiaryServices` where app code uses package services**

In `HDiary/BaseTabView.swift`, add:

```swift
import HDiaryServices
```

after:

```swift
import HDiarySearch
```

In `HDiary/Common/Notification/LocalNotificationManager.swift`, add:

```swift
import HDiaryServices
```

after:

```swift
import HDiaryModel
```

In `HDiary/Common/Navigation/UrlHandler.swift`, add:

```swift
import HDiaryServices
```

after:

```swift
import HDiaryModel
```

- [ ] **Step 3: Remove duplicate app-local deep link definitions**

Delete the app-local `DeepLink` enum from `HDiary/Common/Navigation/UrlHandler.swift`. After the edit, the bottom of the file must end with the `URLHandlerImpl` definition:

```swift
final class URLHandlerImpl: UrlHandler {
  func handle(_ url: URL, mutating path: inout [HDiaryDestination], navigationStore: NavigationStore) {
    guard url.scheme == DeepLink.scheme else {
      Log.Navigation.common.info("scheme not match, skip")
      return
    }

    guard let hostString = url.host(percentEncoded: false) else {
      Log.Navigation.common.info("host not found, skip")
      return
    }

    guard let host = DeepLink.Host(rawValue: hostString) else {
      Log.Navigation.common.info("host not match, skip")
      return
    }

    if host == .moment {
      let path = String(url.path(percentEncoded: false).dropFirst())
      Log.Navigation.common.info("url is \(path) \(url)")
      guard DeepLink.MomentTarget(rawValue: path) != nil else {
        Log.Navigation.common.info("can't find target for moment, skip")
        return
      }
      Task { @MainActor in
        navigationStore.presentedSheet = .addMomnet(uuid: UUID())
      }
    }
  }
}
```

- [ ] **Step 4: Build the app target**

Use XcodeBuildMCP:

```text
xcodebuildmcp-session_show_defaults
xcodebuildmcp-build_sim
```

Expected: build succeeds. If defaults are missing or point at a relative project path not resolved by the tool, call `xcodebuildmcp-session_set_defaults` with `projectPath` set to the absolute path `<repo-root>/HDiary.xcodeproj`, `scheme` set to `HDiary`, and the simulator values from `.xcodebuildmcp/config.yaml`, then rerun `xcodebuildmcp-build_sim`.

- [ ] **Step 5: Run package tests**

Run:

```bash
swift test --package-path HDiaryLibrary
```

Expected: PASS for all package tests.

- [ ] **Step 6: Commit**

Run:

```bash
git add HDiary.xcodeproj/project.pbxproj HDiary/BaseTabView.swift HDiary/Common/Navigation/UrlHandler.swift HDiary/Common/Notification/LocalNotificationManager.swift
git commit -m "refactor: wire hdiary services into app" -m "Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 4: Move root startup side effects out of `BaseTabView`

**Files:**
- Create: `HDiary/Common/Bootstrap/AppRootView.swift`
- Modify: `HDiary/HDiaryApp.swift`
- Modify: `HDiary/BaseTabView.swift`
- Modify: `HDiaryTests/HDiaryTests.swift`

**Interfaces:**
- Consumes:
  - `BaseTabView`
  - `StartupDataMaintenanceService`
  - `SwiftData.ModelContext`
  - `SwiftUI.Environment(\.undoManager)`
- Produces:
  - `@MainActor struct AppRootView: View`
  - `BaseTabView` no longer owns startup maintenance side effects.

- [ ] **Step 1: Replace the template app unit test with a failing root shell test**

Replace `HDiaryTests/HDiaryTests.swift` with:

```swift
//
//  HDiaryTests.swift
//  HDiaryTests
//
//  Created by tigerguo on 2023/6/17.
//

@testable import HDiary
import SwiftUI
import XCTest

@MainActor
final class HDiaryTests: XCTestCase {
  func testAppRootViewCanBeConstructed() {
    let view = AppRootView()

    XCTAssertEqual(String(describing: type(of: view)), "AppRootView")
  }
}
```

- [ ] **Step 2: Run app tests to verify the new test fails**

Use XcodeBuildMCP:

```text
xcodebuildmcp-session_show_defaults
xcodebuildmcp-test_sim
```

Expected: FAIL because `AppRootView` is not defined.

- [ ] **Step 3: Create `AppRootView`**

Create `HDiary/Common/Bootstrap/AppRootView.swift`:

```swift
//
//  AppRootView.swift
//  HDiary
//
//  Created by tigerguo on 2026/7/5.
//

import HDiaryConstants
import HDiaryServices
import SwiftData
import SwiftUI

@MainActor
struct AppRootView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.undoManager) private var undoManager
  @State private var hasPerformedStartupTask = false

  var body: some View {
    BaseTabView()
      .onAppear(perform: performStartupTasksIfNeeded)
  }

  private func performStartupTasksIfNeeded() {
    guard !hasPerformedStartupTask else {
      return
    }
    hasPerformedStartupTask = true
    Log.common.info("Performing startup task")
    StartupDataMaintenanceService().runLoggingFailures(in: modelContext)
    modelContext.undoManager = undoManager
  }
}
```

- [ ] **Step 4: Make `HDiaryApp` use the root shell**

In `HDiary/HDiaryApp.swift`, replace:

```swift
      BaseTabView()
        .withEnvironments()
        .withModelContainer()
```

with:

```swift
      AppRootView()
        .withEnvironments()
        .withModelContainer()
```

- [ ] **Step 5: Remove startup side effects from `BaseTabView`**

In `HDiary/BaseTabView.swift`, remove:

```swift
  @Environment(\.modelContext) private var modelContext
  @Environment(\.undoManager) private var undoManager
```

Remove:

```swift
  @State private var hasPerformedStartupTask = false
```

Remove the `.onAppear` block from `body`:

```swift
    .onAppear {
      guard !hasPerformedStartupTask else {
        return
      }
      hasPerformedStartupTask = true
      Log.common.info("Performing startup task")
      StartupDataMaintenanceService().runLoggingFailures(in: modelContext)
      modelContext.undoManager = undoManager
    }
```

Remove this import if it is no longer used in `BaseTabView.swift`:

```swift
import HDiaryServices
```

Keep `import SwiftData` because `BaseTabView` still uses `FetchDescriptor` and `@Query`.

- [ ] **Step 6: Run app tests to verify the root shell compiles**

Use XcodeBuildMCP:

```text
xcodebuildmcp-session_show_defaults
xcodebuildmcp-test_sim
```

Expected: PASS for `HDiaryTests.testAppRootViewCanBeConstructed`.

- [ ] **Step 7: Run package tests**

Run:

```bash
swift test --package-path HDiaryLibrary
```

Expected: PASS for all package tests.

- [ ] **Step 8: Commit**

Run:

```bash
git add HDiary/Common/Bootstrap/AppRootView.swift HDiary/HDiaryApp.swift HDiary/BaseTabView.swift HDiaryTests/HDiaryTests.swift
git commit -m "refactor: isolate app startup root shell" -m "Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 5: Final dependency and behavior verification

**Files:**
- Read: `HDiaryLibrary/Package.swift`
- Read: `HDiary.xcodeproj/project.pbxproj`
- Read: `HDiary/BaseTabView.swift`
- Read: `HDiary/Common/Bootstrap/AppRootView.swift`
- Read: `HDiary/Common/Navigation/UrlHandler.swift`
- Read: `HDiary/Common/Notification/LocalNotificationManager.swift`

**Interfaces:**
- Consumes:
  - Completed Tasks 1-4.
- Produces:
  - Verified first-phase migration with no app-target duplicate deep link rules and no root startup maintenance inside `BaseTabView`.

- [ ] **Step 1: Confirm `HDiaryServices` dependency direction**

Run:

```bash
rg "import HDiary($|[^A-Za-z0-9_])" HDiaryLibrary/Sources/HDiaryServices HDiaryLibrary/Tests/HDiaryServicesTests
```

Expected: no matches.

Run:

```bash
rg "StartupDataMaintenanceService" HDiaryLibrary/Sources HDiaryLibrary/Tests HDiary
```

Expected output includes:

```text
HDiaryLibrary/Sources/HDiaryServices/StartupDataMaintenanceService.swift
HDiaryLibrary/Tests/HDiaryServicesTests/StartupDataMaintenanceServiceTests.swift
HDiary/Common/Bootstrap/AppRootView.swift
```

Expected output does not include `HDiary/BaseTabView.swift`.

- [ ] **Step 2: Confirm deep link rules are not duplicated in app target**

Run:

```bash
rg "enum DeepLink|DeepLink\\.getAddMomentUrl|DeepLink\\.scheme|DeepLink\\.Host|DeepLink\\.MomentTarget" HDiary HDiaryLibrary/Sources/HDiaryServices HDiaryLibrary/Tests/HDiaryServicesTests
```

Expected output includes one `enum DeepLink` definition in:

```text
HDiaryLibrary/Sources/HDiaryServices/DeepLink.swift
```

Expected output includes usages in:

```text
HDiary/Common/Navigation/UrlHandler.swift
HDiary/Common/Notification/LocalNotificationManager.swift
HDiaryLibrary/Tests/HDiaryServicesTests/DeepLinkTests.swift
```

- [ ] **Step 3: Run all package tests**

Run:

```bash
swift test --package-path HDiaryLibrary
```

Expected: PASS for all package tests.

- [ ] **Step 4: Build and test the app scheme**

Use XcodeBuildMCP:

```text
xcodebuildmcp-session_show_defaults
xcodebuildmcp-build_sim
xcodebuildmcp-test_sim
```

Expected: build succeeds and tests pass.

- [ ] **Step 5: Inspect final diff**

Run:

```bash
git --no-pager status --short
git --no-pager diff --stat
```

Expected: no uncommitted changes after Tasks 1-4. If there are uncommitted changes, stop and inspect them before making another edit or commit.
