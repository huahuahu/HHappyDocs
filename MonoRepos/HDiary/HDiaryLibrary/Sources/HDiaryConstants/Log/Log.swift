//
//  Log.swift
//
//
//  Created by tigerguo on 2024/3/10.
//

import Foundation
import OSLog

private let bundleID = "com.tiger.suzhou.hdiary"

public enum Log {
  public static let common = Logger(subsystem: bundleID, category: "common")

  public static let iap = Logger(subsystem: bundleID, category: "iap")

  public static let data = Logger(subsystem: bundleID, category: "data")

  public static let search = Logger(subsystem: bundleID, category: "search")
  public static let notification = Logger(subsystem: bundleID, category: "notification")

  public enum DB {
    public static let subsystem = "database"
    public static let common = Logger(subsystem: Self.subsystem, category: "common")
    public static let migration = Logger(subsystem: Self.subsystem, category: "migration")
    public static let export = Logger(subsystem: Self.subsystem, category: "export")
  }

  public enum Navigation {
    public static let subsystem = "Navigation"
    public static let common = Logger(subsystem: Self.subsystem, category: "common")
  }
}
