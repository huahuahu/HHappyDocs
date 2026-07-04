//
//  URLHandler.swift
//  Libai
//
//  Created by huahuahu on 2022/1/2.
//
// huahuahu-libai://baidu.com
// huahuahu-libai://annalList
// huahuahu-libai://annalDetail?annalID=1
// huahuahu-libai://location?uniqueName=%E7%A2%8E%E5%8F%B6%E5%9F%8E

import Foundation

struct URLHandler {
  enum Constant {
    static let customURLScheme = "huahuahu-libai"
  }

  enum HostName: String, RawRepresentable {
    case location
    case annalDetail
    case annalList
    case annotate

    var host: HostAndParaname {
      switch self {
      case .location:
        return .location
      case .annalDetail:
        return .annalDetail
      case .annalList:
        return .annalList
      case .annotate:
        return .annotate
      }
    }
  }

  struct HostAndParaname: Equatable {
    let host: HostName
    let paraName: String?

    static let location = Self(host: .location, paraName: "uniqueName")
    static let annalDetail = Self(host: .annalDetail, paraName: "annalID")
    static let annalList = Self(host: .annalList, paraName: nil)
    static let annotate = Self(host: .annotate, paraName: "annote")
  }

  struct Pattern {
    let host: HostAndParaname
    let value: String?

    init(host: URLHandler.HostAndParaname, value: String?) {
      self.host = host
      self.value = value
    }

    init?(url: URL) {
      guard let urlComponent = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
        hLog("can't parse to url component")
        return nil
      }
      guard urlComponent.scheme == Constant.customURLScheme else {
        hLog("not custom scheme")
        return nil
      }
      guard let host = urlComponent.host else {
        hLog("can't find host")
        return nil
      }

      guard let hostName = HostName(rawValue: host) else {
        hLog("can't get host")
        return nil
      }

      let hostAndParameter = hostName.host
      if let paraname = hostAndParameter.paraName {
        if let queryItem = urlComponent.queryItems?.first(where: { element in
          element.name == paraname
        }) {
          self = Self(host: hostAndParameter, value: queryItem.value ?? "")
        }
        else {
          return nil
        }
      }
      else {
        self = Self(host: hostAndParameter, value: nil)
      }
    }

    var url: URL {
      var urlComponent = URLComponents()
      urlComponent.scheme = URLHandler.Constant.customURLScheme
      urlComponent.host = host.host.rawValue
      if let paraName = host.paraName {
        urlComponent.queryItems = [URLQueryItem(name: paraName, value: value)]
      }
      guard let url = urlComponent.url else {
        hLog("unsafe url for \(self)")
        fatalError()
      }

      return url
    }
  }
}
