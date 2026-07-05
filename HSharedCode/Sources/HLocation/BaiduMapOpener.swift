//
//  BaiduMapOpener.swift
//  HSharedCode
//
//  Created by tigerguo on 2024/9/27.
//

import Foundation
#if canImport(UIKit)
  import UIKit

  // https://lbsyun.baidu.com/faq/api?title=webapi/uri/ios
  public struct BaiduMapOpener: HLocationOpener {
    enum Constants {
      static let scheme = "baidumap"
      static let host = "map"
      static let path = "/marker"
      static let locationKey = "location"
      static let titleKey = "title"
      static let contentKey = "content"
      static let srckey = "src"

      static let coordTypeKey = "coord_type"
      static let coordTypeValue = "wgs84"

      // web only
      static let webHost = "api.map.baidu.com"
      static let webOutputKey = "output"
      static let webOutputValue = "html"

//        <a href="baidumap://map/marker?location=40.047669,116.313082&title=我的位置&content=百度奎科大厦&src=ios.baidu.openAPIdemo">地图标点</a>
//    http://api.map.baidu.com/marker?location=40.047669,116.313082&title=我的位置&content=百度奎科大厦&output=html&src=webapp.baidu.openAPIdemo
    }

    let sourceAppName: String

    public init(sourceAppName: String) {
      self.sourceAppName = sourceAppName
    }

    public func open(_ location: HLocation) {
      var urlComponent = URLComponents()
      urlComponent.scheme = Constants.scheme
      urlComponent.host = Constants.host
      urlComponent.path = Constants.path
      var queryItems = [
        URLQueryItem(name: Constants.locationKey, value: "\(location.latitude),\(location.longitude)"),
        URLQueryItem(name: Constants.titleKey, value: location.name),
      ]

//    if let content = location.content {
      queryItems.append(URLQueryItem(name: Constants.contentKey, value: location.content ?? location.name))
//    }

      queryItems.append(contentsOf: [
        URLQueryItem(name: Constants.srckey, value: sourceAppName),
        URLQueryItem(name: Constants.coordTypeKey, value: Constants.coordTypeValue),
      ])

      urlComponent.queryItems = queryItems

      guard let url = urlComponent.url else {
        hLocationLog.error("can't assemble location url for baidu map")
        return
      }

      if UIApplication.shared.canOpenURL(url) {
//           Open in nav
        UIApplication.shared.open(url, options: [:]) { success in
          hLocationLog.info("open \(location.name) \(success, privacy: .public) in baidu map app")
        }
      }
      else {
        urlComponent.host = Constants.webHost
        let outPutQueryItem = URLQueryItem(name: Constants.webOutputKey, value: Constants.webOutputValue)
        urlComponent.queryItems?.append(outPutQueryItem)
        urlComponent.scheme = "https"
        guard let webUrl = urlComponent.url else {
          hLocationLog.error("can't assemble location url for baidu map web ")
          return
        }
        #if canImport(UIKit)
          UIApplication.shared.open(webUrl, options: [:]) { success in
            hLocationLog.info("open \(location.name) \(success, privacy: .public) in baidu map web")
          }
        #endif
      }
    }
  }
#endif
