//
//  LocalizedString.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/3/17.
//

import Foundation

enum LocalizedString {
  static let appName = Bundle.main.localizedInfoDictionary?["CFBundleName"] as? String ?? "ClipMate"

  /// Used in tab bar, for inspector item
  static let home = NSLocalizedString("home", comment: "")
  /// Used in tab bar, for setting item
  static let tabBarSettings = NSLocalizedString("tabbar.settings", comment: "")
  static let sectionInspect = NSLocalizedString("section.inspect", comment: "Interaction Inspect Name")

  /// Used for inspector native entry
  static let inspectorCheckNativeContent = NSLocalizedString("inspector.entry.native.content", comment: "")

  static let inspectorCheckNativeInfo = NSLocalizedString("inspector.entry.native.info", comment: "")
  /// Used for inspector web entry
  static let inspectorCheckWeb = NSLocalizedString("inspector.entry.web", comment: "")

  static let currentInfoInClearPasteboardView = String(localized: "clearPasteboard.currentInfo", comment: "Used as section header for displaying current info")

  static let sectionInteraction = NSLocalizedString("section.interaction", comment: "Interaction Section Name")

  static let unknown = String(localized: "unknown", comment: "")

  static let clearPasteboardAction = String(localized: "interaction.clearPasteboard", comment: "")

  static let utTypeMetaInfo = String(localized: "utType.description.metainfo", comment: "")

  static let utTypeFileExtension = String(localized: "utType.description.fileExtension", comment: "")
  static let utTypeMimeType = String(localized: "utType.description.mimeType", comment: "")
  static let utTypeIsPublic = String(localized: "utType.description.isPublic", comment: "")
  static let utTypeReferenceURL = String(localized: "utType.description.referenceURL", comment: "")
  static let utTypeSuperType = String(localized: "utType.description.supertype", comment: "")
  static let utTypeDescription = String(localized: "utType.description.description", comment: "")
  static let utTypeIdentifier = String(localized: "utType.description.identifier", comment: "")
  static let pasteboardItemRepresentaionType = String(localized: "pasteboardItem.representaion.type", comment: "")
  static let pasteboardItemRepresentaionSystemDescription = String(localized: "pasteboardItem.representaion.systemDescription", comment: "Used as navigation item for calling String(describing:)")

  static let length = String(localized: "length", comment: "")
  static let size = String(localized: "size", comment: "")
  static let preview = String(localized: "preview", comment: "")

  static let permissionForLocalAuthReason = String(localized: "permission.localAuthReason", comment: "alert shown to user when requesting local auth permisson")

  static let item = String(localized: "item", comment: "Used to show clipboard item")

  static func item(for index: Int) -> String {
    let indexString = "\(index)"
    return String(localized: "inspector.native.item \(indexString)", comment: "the index-th item")
  }
}
