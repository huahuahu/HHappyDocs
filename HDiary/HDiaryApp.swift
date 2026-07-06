import HDiaryAppFeature
import SwiftUI

@main
struct HDiaryApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate

  var body: some Scene {
    HDiaryFeatureApp().body
  }
}
