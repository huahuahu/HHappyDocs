//
//  Log.swift
//
//
//  Created by tigerguo on 2024/3/10.
//

import OSLog

public enum Log {
  public static let subsystem = "com.tiger.suzhou.hdiary"

  public static let common = Logger(subsystem: subsystem, category: "common")

  public static let iap = Logger(subsystem: subsystem, category: "iap")

  public static let data = Logger(subsystem: subsystem, category: "data")

  public static let search = Logger(subsystem: subsystem, category: "search")
  public static let notification = Logger(subsystem: subsystem, category: "notification")

  public enum Widget {
    public static let snapshot = Logger(subsystem: Log.subsystem, category: "widget.snapshot")
    public static let timeline = Logger(subsystem: Log.subsystem, category: "widget.timeline")
    public static let intent = Logger(subsystem: Log.subsystem, category: "widget.intent")
  }

  public enum DB {
    public static let common = Logger(subsystem: Log.subsystem, category: "database.common")
    public static let migration = Logger(subsystem: Log.subsystem, category: "database.migration")
    public static let export = Logger(subsystem: Log.subsystem, category: "database.export")
  }

  public enum Navigation {
    public static let common = Logger(subsystem: Log.subsystem, category: "navigation")
  }
}
