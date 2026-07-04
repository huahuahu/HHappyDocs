//
//  InspectEntry.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/3/17.
//

import Foundation

enum InspectEntry: CaseIterable, Identifiable {
  #if os(iOS) || os(visionOS)
    case checkNativeInfo
  #endif
  case checkNativeContent
  case checkWeb

  var text: String {
    switch self {
    #if os(iOS) || os(visionOS)
      case .checkNativeInfo:
        return LocalizedString.inspectorCheckNativeInfo
    #endif
    case .checkNativeContent:
      return LocalizedString.inspectorCheckNativeContent
    case .checkWeb:
      return LocalizedString.inspectorCheckWeb
    }
  }

  var id: String {
    text
  }
}
