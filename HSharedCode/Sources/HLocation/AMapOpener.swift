//
//  AMapOpener.swift
//  HSharedCode
//
//  Created by tigerguo on 2024/9/27.
//

import Foundation
#if os(iOS)
  import UIKit

  /// 高德地图打开位置
  public struct AMapOpener: HLocationOpener {
    let sourceAppName: String

    public init(sourceAppName: String) {
      self.sourceAppName = sourceAppName
    }

//    https://lbs.amap.com/api/amap-mobile/guide/ios/marker
    enum Constants {
      static let scheme = "iosamap"
      static let host = "viewMap"
      static let latKey = "lat"
      static let lonKey = "lon"
      static let sourceApplicationKey = "sourceApplication"
      static let poinameKey = "poiname"
    }

    // https://lbs.amap.com/api/uri-api/guide/mobile-web/point
    enum WebConstants {
      static let scheme = "https"
      static let host = "uri.amap.com"
      static let path = "/marker"
      static let positionKey = "position"
      static let nameKey = "name"
      static let srcKey = "src"
      static let coordinateKey = "coordinate"
      static let coordinateVale = "gaode"
      static let callnativeKey = "callnative"
      static let callnativeValue = "1"
    }

    public func open(_ location: HLocation) {
      if !openInApp(location) {
        openInWeb(location)
      }
    }

    private func openInApp(_ location: HLocation) -> Bool {
      var urlComponent = URLComponents()
      urlComponent.scheme = Constants.scheme
      urlComponent.host = Constants.host
      urlComponent.queryItems = [
        URLQueryItem(name: Constants.sourceApplicationKey, value: sourceAppName),
        URLQueryItem(name: Constants.latKey, value: location.latitude.description),
        URLQueryItem(name: Constants.lonKey, value: location.longitude.description),
        URLQueryItem(name: Constants.poinameKey, value: location.name),
        URLQueryItem(name: "dev", value: "0"),
      ]
      guard let url = urlComponent.url else {
        hLocationLog.error("can't assemble location url, \(urlComponent.description)")
        return false
      }
      if UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url, options: [:]) { success in
          hLocationLog.info(" open \(location.name) in amap, result is \(success, privacy: .public)")
        }
        return true
      }
      else {
        return false
      }
    }

    private func openInWeb(_ location: HLocation) {
      var urlComponent = URLComponents()
      urlComponent.scheme = WebConstants.scheme
      urlComponent.host = WebConstants.host
      urlComponent.path = WebConstants.path

      urlComponent.queryItems = [
        URLQueryItem(name: WebConstants.positionKey, value: "\(location.longitude),\(location.latitude)"),
        URLQueryItem(name: WebConstants.nameKey, value: location.name),
        URLQueryItem(name: WebConstants.srcKey, value: sourceAppName),
        URLQueryItem(name: WebConstants.coordinateKey, value: WebConstants.coordinateVale),
        URLQueryItem(name: WebConstants.callnativeKey, value: WebConstants.callnativeValue),
      ]
      guard let url = urlComponent.url else {
        hLocationLog.error("can't assemble location url, \(urlComponent.description)")
        return
      }

      #if os(iOS)
        UIApplication.shared.open(url, options: [:]) { success in
          hLocationLog.info(" open \(location.name) in amap web, result is \(success, privacy: .public)")
        }
      #endif
    }
  }
#endif
