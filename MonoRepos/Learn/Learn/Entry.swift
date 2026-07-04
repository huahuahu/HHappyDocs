//
//  Entry.swift
//  Learn
//
//  Created by tigerguo on 2023/9/5.
//

import Foundation
import SwiftUI

enum Entry: CaseIterable, Identifiable, Hashable {
  case gridLayout
  case media
  case interaction
  case list
  case calendar // Added new case
  case aiDemo
  case swiftUIComponent
  case search

  var title: String {
    switch self {
    case .gridLayout:
      "Grid layout"
    case .media:
      "Media"
    case .interaction:
      "interaction"
    case .list:
      "List"
    case .calendar: // Added new case
      "Calendar"
    case .aiDemo:
      "AI Demo"
    case .swiftUIComponent:
      "SwiftUI Component"
    case .search:
      "Search"
    }
  }

  var subtitle: String {
    switch self {
    case .gridLayout:
      "table like data, left column should only take needed place"
    case .media:
      "Media operations"
    case .interaction:
      "User Interactions such as Drag & Drop"
    case .list:
      "Every thing about list"
    case .calendar: // Added new case
      "Calendar related stuff"
    case .aiDemo:
      "AI Demo"
    case .swiftUIComponent:
      "SwiftUI component demos"
    case .search:
      "Search demos"
    }
  }

  @ViewBuilder
  @MainActor var destination: some View {
    switch self {
    case .gridLayout:
      TableLikeLayout()
    case .media:
      MediaLearnList()
    case .interaction:
      InteractionListView()
    case .list:
      ListEntryView()
    case .calendar:
      CalendarListView()
    case .aiDemo:
      AIDemo.AIListView()
    case .swiftUIComponent:
      SwiftUIDemo.ListView()
    case .search:
      SearchDemo.ListView()
    }
  }

  var id: Self {
    self
  }
}
