//
//  Log.swift
//  Learn
//
//  Created by tigerguo on 2023/11/12.
//

import Foundation
import OSLog

enum Log {
  /// Using your bundle identifier is a great way to ensure a unique identifier.
  private static var subsystem = Bundle.main.bundleIdentifier!

  static let common = Logger(subsystem: subsystem, category: "common")
}
