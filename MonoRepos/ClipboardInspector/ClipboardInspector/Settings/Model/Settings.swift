//
//  Settings.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/4/2.
//

import Foundation
import HUIComponent
import SwiftUI

@MainActor
class Settings: ObservableObject {
  static let shared = Settings()
  private init() {
    #if DEBUG
    #endif
    pTheme = HTheme(rawValue: theme) ?? .auto
    pAppLockEnabled = appLockEnabled
  }

  @Published var pTheme = HTheme.auto {
    didSet {
      print("ptheme \(oldValue) -> \(pTheme)")
      theme = pTheme.rawValue
    }
  }

  @Published var pAppLockEnabled = false {
    didSet {
      print("pAppLockEnabled \(oldValue) -> \(pAppLockEnabled)")
      appLockEnabled = pAppLockEnabled
    }
  }

  @AppStorage(UserDefaultKey.theme) private var theme = 0
  @AppStorage(UserDefaultKey.appLockEnabled) private var appLockEnabled = false
}
