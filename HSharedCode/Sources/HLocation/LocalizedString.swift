//
//  LocalizedString.swift
//  HUIComponent
//
//  Created by tigerguo on 2023/3/19.
//

import Foundation

private class DC {}

public enum HLocationString {
  public static let gaodeMap = String(localized: "gaode map", bundle: .module, comment: "AMap name")
//    LocalizedStringResource("gaode map", table: "Localizable",  bundle: .forClass(DC.self), comment: "AMap name")
  public static let baiduMap = String(localized: "baidu map", bundle: .module, comment: "baidu map name")
//    LocalizedStringResource("baidu map", table: "Localizable", comment: "baidu map name")
//    public static let dd = localsre
//    (localized: "settings", bundle: .module, comment: "Used for settings")
}

extension LocalizedStringResource {
  func hDocLocalized() -> String {
    String(localized: .init(stringLiteral: self.key), bundle: .module)
  }
}
