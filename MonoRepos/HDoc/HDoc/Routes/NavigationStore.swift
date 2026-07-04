//
//  NavigationStore.swift
//  HDoc
//
//  Created by tigerguo on 2023/12/29.
//

import Foundation
import HDocAppConstants
import SwiftUI

@MainActor
@Observable final class NavigationStore {
  var path = [HDocNavigationTarget]()

  private let urlHandler: UrlHandler
  private let activityHandler: ActivityHandler
  private let uuid: UUID
  var presentedSheet: SheetDestination? {
    didSet {
      Log.navigation.info("presentation sheet -> \(String(describing: self.presentedSheet))")
    }
  }

  convenience init() {
    self.init(urlHandler: URLHandlerImpl(), activityHandler: ActivityHandlerImpl())
  }

  deinit {
    Log.navigation.debug("\(self.uuid) navigationstore deinited")
  }

  private init(urlHandler: UrlHandler, activityHandler: ActivityHandler) {
    self.uuid = UUID()
    Log.navigation.info("\(self.uuid) navigationstore init")
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
