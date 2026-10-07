import SwiftUI
import UIKit

/// Provides a key window for snapshot unit tests; contains no production services or data.
@main
struct SnapshotHostApp: App {
  init() {
    // Capture settled system controls, not intermediate navigation/Tab selection animations.
    UIView.setAnimationsEnabled(false)
    // Eagerly localized shared strings use the host's language, not SwiftUI's locale.
    // These preferences belong only to this dedicated snapshot host.
    UserDefaults.standard.set(["zh-Hans"], forKey: "AppleLanguages")
    UserDefaults.standard.set("zh_CN", forKey: "AppleLocale")
  }

  var body: some Scene {
    WindowGroup {
      Color.clear
        .background(SnapshotWindowReader())
    }
  }
}

/// Lets snapshot tests use this scene's actual window and asymmetric safe area.
@MainActor
enum SnapshotHostWindow {
  static weak var window: UIWindow?
}

private struct SnapshotWindowReader: UIViewRepresentable {
  func makeUIView(context: Context) -> WindowReaderView {
    WindowReaderView()
  }

  func updateUIView(_ uiView: WindowReaderView, context: Context) {}

  final class WindowReaderView: UIView {
    override func didMoveToWindow() {
      super.didMoveToWindow()
      if let window {
        SnapshotHostWindow.window = window
      }
    }
  }
}
