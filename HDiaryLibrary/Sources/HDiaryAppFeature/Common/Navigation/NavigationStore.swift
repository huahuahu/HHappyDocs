//
//  NavigationStore.swift
//  HDiary
//
//  Created by tigerguo on 2023/10/26.
//

#if os(iOS)

import Foundation
import HDiaryConstants
import HDiaryModel
import SwiftUI

@MainActor
@Observable final class NavigationStore {
//  static let shared = NavigationStore()
  var path = [HDiaryDestination]()

//  var momentPath = NavigationPath()
//  var libraryPath = NavigationPath()
//  var settingPath = NavigationPath()

  private let urlHandler: UrlHandler
  private let activityHandler: ActivityHandler
  var presentedSheet: SheetDestination? {
    didSet {
      Log.common.info("presentation sheet -> \(String(describing: self.presentedSheet))")
    }
  }

  convenience init() {
    self.init(urlHandler: URLHandlerImpl(), activityHandler: ActivityHandlerImpl())
  }

  private init(urlHandler: UrlHandler, activityHandler: ActivityHandler) {
    Log.common.info("\(UUID()) navigationstore init")
    self.urlHandler = urlHandler
    self.activityHandler = activityHandler
  }

  func handle(_ activity: NSUserActivity) {
    activityHandler.handle(activity, mutating: &path)
  }

  func handle(_ url: URL) {
    urlHandler.handle(url, mutating: &path, navigationStore: self)
  }
}

#endif
