//
//  Log.swift
//
//
//  Created by tigerguo on 2023/12/29.
//

import Foundation
import OSLog

private let bundleID = "com.tiger.suzhou.hdoc"
public enum Log {
  public static let common = Logger(subsystem: bundleID, category: "common")

  public static let navigation = Logger(subsystem: bundleID, category: "navigation")

  public static let data = Logger(subsystem: bundleID, category: "data")

  public static let iap = Logger(subsystem: bundleID, category: "iap")

  public static let map = Logger(subsystem: bundleID, category: "map")
}
