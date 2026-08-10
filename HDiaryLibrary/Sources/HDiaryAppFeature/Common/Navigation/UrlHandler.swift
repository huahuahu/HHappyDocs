//
//  UrlHandler.swift
//  HDiary
//
//  Created by tigerguo on 2023/10/26.
//

#if os(iOS)

import Foundation
import HDiaryConstants
import HDiaryModel
import SwiftUI

protocol UrlHandler {
  func handle(_ url: URL, mutating: inout [HDiaryDestination], navigationStore: NavigationStore)
}

final class URLHandlerImpl: UrlHandler {
  func handle(_ url: URL, mutating path: inout [HDiaryDestination], navigationStore: NavigationStore) {
    guard url.scheme == DeepLink.scheme else {
      Log.Navigation.common.log(level: DiagnosticLogging.level(for: .info), "scheme not match, skip")
      return
    }

    guard let hostString = url.host(percentEncoded: false) else {
      Log.Navigation.common.log(level: DiagnosticLogging.level(for: .info), "host not found, skip")
      return
    }

    guard let host = DeepLink.Host(rawValue: hostString) else {
      Log.Navigation.common.log(level: DiagnosticLogging.level(for: .info), "host not match, skip")
      return
    }

    if host == .moment {
      let path = String(url.path(percentEncoded: false).dropFirst())
      Log.Navigation.common.log(level: DiagnosticLogging.level(for: .info), "url is \(path) \(url)")
      guard DeepLink.MomentTarget(rawValue: path) != nil else {
        Log.Navigation.common.log(level: DiagnosticLogging.level(for: .info), "can't find target for moment, skip")
        return
      }
      Task { @MainActor in
        navigationStore.presentedSheet = .addMomnet(uuid: UUID())
      }
    }
  }
}

enum DeepLink {
  static let scheme = "hdiarydl"
  enum Host: String, RawRepresentable {
    case moment
    case library
    case setting
  }

//    enum

  enum MomentTarget: String, RawRepresentable {
    case add
  }

  static func getAddMomentUrl() -> URL? {
    var urlComponents = URLComponents()
    urlComponents.scheme = Self.scheme
    urlComponents.host = Self.Host.moment.rawValue
    urlComponents.path = "/\(MomentTarget.add.rawValue)"
    return urlComponents.url
  }

//    static func get
}

#endif
