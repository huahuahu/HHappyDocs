//
//  HUTModel.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/3/19.
//

import Foundation
import HLocalization
import UniformTypeIdentifiers

struct UTProperty: Identifiable {
  let key: String
  let value: String
  var id: String {
    key
  }
}

extension UTType: @retroactive Identifiable {
  public var id: String {
    description
  }
}

extension UTType {
  var properties: [UTProperty] {
    return [
      UTProperty(key: LocalizedString.utTypeIdentifier, value: identifier),
      UTProperty(key: LocalizedString.utTypeMimeType, value: preferredMIMEType ?? LocalizedString.unknown),
      UTProperty(key: LocalizedString.utTypeFileExtension, value: preferredFilenameExtension ?? LocalizedString.unknown),
      UTProperty(key: LocalizedString.utTypeIsPublic, value: isPublic.localizedDescription),
      UTProperty(key: LocalizedString.utTypeDescription, value: localizedDescription ?? LocalizedString.unknown),
    ]
  }
}
