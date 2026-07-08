import HDiaryAppFeature
import HDiaryWidgetIntents
import SwiftUI

@main
struct HDiaryApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate

  init() {
    _ = HDiaryWidgetIntentsAppIntentsPackage.self
    _ = MomentWidgetIntent.self
  }

  var body: some Scene {
    HDiaryFeatureApp().body
  }
}
