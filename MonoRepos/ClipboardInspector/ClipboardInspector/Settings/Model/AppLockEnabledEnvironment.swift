//
//  AppLockEnabledEnvironment.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/12/21.
//

import Foundation
import SwiftUI

// 1. Create the key with a default value
private struct AppLockEnabledKey: EnvironmentKey {
  static let defaultValue = false
}

// 2. Extend the environment with our property
extension EnvironmentValues {
  var appLockEnabled: Bool {
    get { self[AppLockEnabledKey.self] }
    set { self[AppLockEnabledKey.self] = newValue }
  }
}
