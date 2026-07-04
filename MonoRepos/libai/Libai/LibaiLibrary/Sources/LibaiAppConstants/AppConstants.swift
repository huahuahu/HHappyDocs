//
//  AppConstants.swift
//
//
//  Created by tigerguo on 2024/2/29.
//

import Foundation

public enum AppConstants {
  public static let groupName = "group.com.tiger.suzhou.libai"
  public static let cloudKitContainerIdentifier = "iCloud.com.tigerhuahuahu.suzhou.libai"

  public static let containerURL: URL = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: Self.groupName)!

  public static var poemsURL: URL {
    containerURL.appendingPathComponent("poems.json")
  }
}
