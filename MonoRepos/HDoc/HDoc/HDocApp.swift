//
//  HDocApp.swift
//  HDoc
//
//  Created by tigerguo on 2023/12/29.
//

import HDocAppConstants
import HDocLocation
import HDocModel
import HUIComponent
import SwiftData
import SwiftUI

@main @MainActor
struct HDocApp: App {
  @State var userPreferences = UserPreferences.shared
  @State var locationManager = HDocLocationManager()
  @State var appRoute = AppRoute()

  var body: some Scene {
    WindowGroup {
      BaseTabView()
        .recordSubscriptionPassStatusTask()
        .theme(HTheme(userPreferences.theme))
    }
    .modelContainer(HDocContainer.iCloudContainer)
    .environment(userPreferences)
    .environment(locationManager)
    .environment(appRoute)
  }
}
