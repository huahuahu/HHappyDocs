//
//  File.swift
//
//
//  Created by tigerguo on 2023/7/23.
//
#if os(iOS)

  import Foundation
  import SwiftUI

  /// Used to create sfsymbols in HDiaryApp in a unified approach
  public enum HDiarySymbol: String {
    /// Tap this to show edit view
    case edit = "pencil"

    case tag

    case participant = "person"

    case chart = "chart.xyaxis.line"

    case star = "star.fill"

    case bell
    case checkmark

    case buy = "cart"
    case restorePurchase = "arrow.counterclockwise"

    case xMark = "xmark"
    case privacyPolicy = "hand.raised.fill"

    case termOfUse = "doc.text.magnifyingglass"
    case skip = "arrow.right"

    case bug = "ladybug"

    case sort = "arrow.up.arrow.down"
    case exportDoc = "arrow.up.doc"
    case about = "info.circle"
    case questionMark = "questionmark"
    case trash
    case pieChart = "chart.pie"
    case hourglass
    case iCloud = "icloud"
    case refresh = "arrow.clockwise"
    case calendar
    case storageSize = "server.rack"
    case filter = "line.horizontal.3.decrease.circle"
    case plus
    case lightbulb
    case squareDashed = "square.dashed"
    case alphabeticalOrder = "textformat.abc"
    case number
  }

  public extension Image {
    init(hDiarySymbol symbol: HDiarySymbol) {
      self.init(systemName: symbol.rawValue)
    }
  }

#endif
