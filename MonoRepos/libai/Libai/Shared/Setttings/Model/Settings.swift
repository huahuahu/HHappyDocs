//
//  Settings.swift
//  Libai
//
//  Created by huahuahu on 2021/12/25.
//

import Combine
import Foundation
import SwiftUI

class Settings: ObservableObject {
  private init() {
    #if DEBUG
      pUseDebugUrlForWeb = useDebugUrlForWeb
    #endif
    pTheme = Theme(rawValue: theme) ?? .auto
  }

  static let shared = Settings()

  @AppStorage(UserDefaultKey.useDebugUrlForWeb) var useDebugUrlForWeb = false {
    didSet {
      dataLog("useDebugUrlForWeb \(useDebugUrlForWeb)")
      pUseDebugUrlForWeb = useDebugUrlForWeb
    }
  }

  @AppStorage(UserDefaultKey.theme) var theme = 0 {
    didSet {
      dataLog("huahuahu theme \(theme)")
      pTheme = Theme(rawValue: theme) ?? .auto
    }
  }

  @Published var pTheme = Theme.auto
  @Published var pUseDebugUrlForWeb = false
}
