//
//  HAppInfo.swift
//  HFoundation
//
//  Created by tigerguo on 2023/4/24.
//

import Foundation

public enum HAppInfo {
  public static func getAppVersion() -> String? {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
  }

  public static let appName = String(localized: "CFBundleDisplayName", table: "InfoPlist")
}
