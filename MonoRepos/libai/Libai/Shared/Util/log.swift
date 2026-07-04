//
//  log.swift
//  Libai
//
//  Created by huahuahu on 2022/1/2.
//

import Foundation
import os.log

private enum Constants {
  static let fileNameMaxLength = 20
  static let functionNameMaxLength = 20
}

enum Log {
  static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS "
    return formatter
  }()
}

extension Logger {
  private static var subsystem = Bundle.main.bundleIdentifier!

  static let general = Logger(subsystem: subsystem, category: "general")
  static let data = Logger(subsystem: subsystem, category: "data")
  static let tagCollectionView = Logger(subsystem: subsystem, category: "tagCollection")
  static let ui = Logger(subsystem: subsystem, category: "ui")
  static let wordCloud = Logger(subsystem: subsystem, category: "wordCloud")
  static let widget = Logger(subsystem: subsystem, category: "widget")
  static let deepLink = Logger(subsystem: subsystem, category: "deepLink")
  static let navigation = Logger(subsystem: subsystem, category: "navigation")
  static let coreData = Logger(subsystem: subsystem, category: "coreData")
}

public enum LogScenario: String {
  case `default` = ""
  case tagColltionView
  case ui
  case wordCloud
  case wiget
  case deepLink
  case data
  case navigation
  case coreData

  var logger: Logger {
    switch self {
    case .default:
      return .general
    case .tagColltionView:
      return .tagCollectionView
    case .ui:
      return .ui
    case .wordCloud:
      return .wordCloud
    case .wiget:
      return .widget
    case .deepLink:
      return .deepLink
    case .data:
      return .data
    case .navigation:
      return .navigation
    case .coreData:
      return .coreData
    }
  }
}

public func hLog(_ message: String, filename: String = #file, functionName: String = #function) {
  let url = URL(fileURLWithPath: filename)
  Logger.general.info("\(url.deletingPathExtension().lastPathComponent, align: .right(columns: Constants.fileNameMaxLength)): \(functionName, align: .left(columns: Constants.functionNameMaxLength)) \(message)")
}

public func dataLog(_ message: String, filename: String = #file, functionName: String = #function) {
  let url = URL(fileURLWithPath: filename)
  Logger.data.info("\(url.deletingPathExtension().lastPathComponent, align: .right(columns: Constants.fileNameMaxLength)): \(functionName, align: .left(columns: Constants.functionNameMaxLength)) \(message)")
}

public func hLog(_ message: String, scenerio: LogScenario, filename: String = #file, functionName: String = #function) {
  let url = URL(fileURLWithPath: filename)
  scenerio.logger.info("\(url.deletingPathExtension().lastPathComponent, align: .right(columns: Constants.fileNameMaxLength)): \(functionName, align: .left(columns: Constants.functionNameMaxLength)) \(message)")
}
