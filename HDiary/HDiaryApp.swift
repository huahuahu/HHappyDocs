//
//  HDiaryApp.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/17.
//

import HDiaryModel
import SwiftData
import SwiftUI

@main
struct HDiaryApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

  var body: some Scene {
    WindowGroup {
      AppRootView()
        .withEnvironments()
        .withModelContainer()
    }
  }
}
