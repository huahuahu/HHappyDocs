//
//  LibaiApp.swift
//  Shared
//
//  Created by huahuahu on 2021/12/25.
//

import LibaiModel
import SwiftUI

@main
struct LibaiApp: App {
  @StateObject var settings = Settings.shared
  @StateObject var deepLinkHandler = DeepLinkHandler()
  @StateObject var navigationModel = HNavigationModel()

  // TODO: Find a place to load it on init
  var viewContext = HCoreDataStack.shared.privateManagedContext

  var body: some Scene {
    WindowGroup {
      HTabView()
        .environmentObject(settings)
        .environmentObject(navigationModel)
        .environment(\.managedObjectContext, HCoreDataStack.shared.privateManagedContext)
        .theme(settings.pTheme)
        .onContinueUserActivity("PoemIntent") { userActivity in
          hLog("PoemIntent activity \(userActivity.activityType) \(String(describing: userActivity.title))", scenerio: .deepLink)
          deepLinkHandler.openRandomPoem()
        }
    }
    .modelContainer(LibaiContainer.iCloudContainer)
  }
}
