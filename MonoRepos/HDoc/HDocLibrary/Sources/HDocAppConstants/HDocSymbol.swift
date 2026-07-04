//
//  HDocSymbol.swift
//
//
//  Created by tigerguo on 2023/12/29.
//

import Foundation
import SwiftUI

/// Used to create sfsymbols in HDoc in a unified approach
public enum HDocSymbol: String {
  /// Tap this to show edit view
  case edit = "pencil"

  case tag

  case participant = "person"

  case chart = "chart.xyaxis.line"

  case star

  case bell
  case checkmark

  case gear
  case house
  case plus
  case sort = "arrow.up.arrow.down"
  case circle
  case calendar
  case cross
  case library = "cube.box"
  case exportDoc = "arrow.up.doc"
  case medicalSite = "building"
  case patient = "person.2"
  case buy = "cart"
  case restorePurchase = "arrow.counterclockwise"

  case xMark = "xmark"

  case trash

  case skip = "arrow.right"

  case privacyPolicy = "hand.raised.fill"

  case location

  case car
  case map

  case iCloud = "icloud"

  case refresh = "arrow.clockwise"
}

public extension Image {
  init(hdocSymbol symbol: HDocSymbol) {
    self.init(systemName: symbol.rawValue)
  }
}
