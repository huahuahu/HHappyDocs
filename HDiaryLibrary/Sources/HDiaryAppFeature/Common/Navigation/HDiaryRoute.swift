//
//  HDiaryRoute.swift
//  HDiary
//
//  Created by tigerguo on 2024/9/29.
//

#if os(iOS)

import Foundation
import Observation

@Observable @MainActor
final class HDiaryRoute {
  private init() {}

  static let shared = HDiaryRoute()

  var selectedTab: HDiaryTab = .content
  var contentNavigationStore = NavigationStore()
  var libraryNavigationStore = NavigationStore()
  var settingNavigationStore = NavigationStore()
}

enum HDiaryTab: String, RawRepresentable, Hashable {
  case content
  case library
  case setting
}

#endif
