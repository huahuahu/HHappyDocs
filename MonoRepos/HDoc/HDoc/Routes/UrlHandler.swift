//
//  UrlHandler.swift
//  HDiary
//
//  Created by tigerguo on 2023/10/26.
//

import Foundation
import HDocAppConstants
import SwiftUI

protocol UrlHandler {
  func handle(_ url: URL, mutating: inout [HDocNavigationTarget], navigationStore: NavigationStore)
}

final class URLHandlerImpl: UrlHandler {
  func handle(_ url: URL, mutating path: inout [HDocNavigationTarget], navigationStore: NavigationStore) {
    guard url.scheme == DeepLink.scheme else {
      Log.navigation.info("scheme not match, skip")
      return
    }

    guard let hostString = url.host(percentEncoded: false) else {
      Log.navigation.info("host not found, skip")
      return
    }

    guard let host = DeepLink.Host(rawValue: hostString) else {
      Log.navigation.info("host not match, skip")
      return
    }

    if host == .home {
      let path = String(url.path(percentEncoded: false).dropFirst())
      Log.navigation.info("url is \(path) \(url)")
//      guard let target = DeepLink.MomentTarget(rawValue: path) else {
//          Log.navigation.info("can't find target for moment, skip")
//        return
//      }
//      Task { @MainActor in
//        navigationStore.presentedSheet = .addMomnet(uuid: UUID())
//      }
    }
  }
}

enum DeepLink {
  static let scheme = "hdocdl"
  enum Host: String, RawRepresentable {
    case home
    case setting
  }

//  enum MomentTarget: String, RawRepresentable {
//    case add
//  }
//
//  static func getAddMomentUrl() -> URL? {
//    var urlComponents = URLComponents()
//    urlComponents.scheme = Self.scheme
//    urlComponents.host = Self.Host.moment.rawValue
//    urlComponents.path = "/\(MomentTarget.add.rawValue)"
//    return urlComponents.url
//  }
}
