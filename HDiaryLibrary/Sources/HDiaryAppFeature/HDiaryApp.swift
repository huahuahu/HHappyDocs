//
//  HDiaryApp.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/17.
//

import HDiaryModel
import SwiftData
import SwiftUI

public struct HDiaryFeatureApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate

  public init() {}

  public var body: some Scene {
    WindowGroup {
      BaseTabView()
        .withEnvironments()
        .withModelContainer()
    }
  }
}
