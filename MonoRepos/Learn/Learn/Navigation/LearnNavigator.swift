//
//  LearnNavigator.swift
//  Learn
//
//  Created by tigerguo on 2023/11/12.
//

import Foundation
import SwiftUI

struct LearnNavigator: ViewModifier {
  func body(content: Content) -> some View {
    content.navigationDestination(for: NavigationTarget.self) { target in
      switch target {
      case .mediaLearn(item: let entry):
        entry.entryView
      case .entry(entry: let entry):
        entry.destination
      case .phAsset(identifier: let identifier):
        PHAssetMetaInfoView(identifier: identifier)
      case .interaction(entry: let entry):
        entry.destination()
      case .listEntry(entry: let entry):
        entry.destination()
      case .calendar(entry: let entry):
        entry.entryView
      case .ai(entry: let entry):
        entry.entryView
      case .swiftUIDemo(entry: let entry):
        entry.entryView
      case .search(entry: let entry):
        entry.entryView
      }
    }
  }
}

extension View {
  func withNavigator() -> some View {
    modifier(LearnNavigator())
  }
}

enum NavigationTarget: Hashable {
  case entry(entry: Entry)
  case mediaLearn(item: MediaLearnEntry)
  case phAsset(identifier: String)
  case interaction(entry: InteractionEntry)
  case listEntry(entry: ListEntry)
  case calendar(entry: CalendarListEntry)
  case ai(entry: AIDemo.AIDemoEntry)
  case swiftUIDemo(entry: SwiftUIDemo.SwiftUIDemoEntry)
  case search(entry: SearchDemo.SearchDemoEntry)
}
