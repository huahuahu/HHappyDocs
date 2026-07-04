//
//  HNavigationModel.swift
//  Libai (iOS)
//
//  Created by tigerguo on 2022/9/7.
//

import Combine
import Foundation
import SwiftUI

class HNavigationModel: ObservableObject {
  @Published var bioPath = NavigationPath()

  @Published var creativeWorkPath = NavigationPath()

  @Published var collectionPath = NavigationPath()

  @Published var settingsPath = NavigationPath()

  @AppStorage(UserDefaultKey.selectedTab) var selectedTab = Tab.annal {
    didSet {
      pSelectedTab = selectedTab
    }
  }

  @Published var pSelectedTab = Tab.annal

  private var cancellables = Set<AnyCancellable>()
  init() {
    $bioPath.sink { path in
      hLog("new bio path is \(path), \(path.count)", scenerio: .navigation)
    }
    .store(in: &cancellables)
  }

  func append(newItem: any Hashable) {
    switch selectedTab {
    case .annal:
      bioPath.append(newItem)
    case .poems:
      creativeWorkPath.append(newItem)
    case .collections:
      collectionPath.append(newItem)
    case .settings:
      settingsPath.append(newItem)
    }
  }

//    var currentPath: NavigationPath {
//        switch selectedTab {
//        case .annal:
//            return bioPath
//        case .poems:
//            return creativeWorkPath
//        case .colletions:
//            return collectionPath
//        case .settings:
//            return settingsPath
//        }
//    }
}

struct PoemKey: Hashable, Codable {
  let poemID: Int
}

enum Tab: Int, Hashable {
  case annal
  case poems
  case collections
  case settings
}
