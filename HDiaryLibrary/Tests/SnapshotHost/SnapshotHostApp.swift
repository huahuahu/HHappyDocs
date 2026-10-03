import SwiftUI

/// Provides a key window for snapshot unit tests; contains no production services or data.
@main
struct SnapshotHostApp: App {
  init() {
    // Eagerly localized shared strings use the host's language, not SwiftUI's locale.
    // These preferences belong only to this dedicated snapshot host.
    UserDefaults.standard.set(["zh-Hans"], forKey: "AppleLanguages")
    UserDefaults.standard.set("zh_CN", forKey: "AppleLocale")
  }

  var body: some Scene {
    WindowGroup {
      Color.clear
    }
  }
}
