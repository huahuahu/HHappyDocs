//
//  CalendarListEntry.swift
//  Learn
//
//  Created by tigerguo on 2023/11/12.
//

import Foundation
import SwiftUI

enum CalendarListEntry: CaseIterable, Identifiable, Hashable {
  case calendarViewUIKit

  var id: Self {
    self
  }

  var title: String {
    switch self {
    case .calendarViewUIKit:
      return "Calendar View UIKit"
    }
  }

  @MainActor
  @ViewBuilder var entryView: some View {
    switch self {
    case .calendarViewUIKit:
      CalendareViewDemo()
    }
  }
}
