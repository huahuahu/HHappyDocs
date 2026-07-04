//
//  SearchDemoEntry.swift
//  Learn
//
//  Created by tigerguo on 2025/1/24.
//

import Foundation
import SwiftData
import SwiftUI

enum SearchDemo {}

extension SearchDemo {
  enum SearchDemoEntry: CaseIterable, Identifiable, Hashable {
    case spotlight
    case indexSwiftData

    var id: Self {
      self
    }

    var title: String {
      switch self {
      case .spotlight:
        return "Spotlight"
      case .indexSwiftData:
        return "Index SwiftData using spotlight"
      }
    }

    @MainActor
    @ViewBuilder var entryView: some View {
      switch self {
      case .spotlight:
        SpotlightDemoView()
      case .indexSwiftData:
        IndexSwiftDataDemoView()
          .modelContainer(IndexContainer.icloudContainer)
      }
    }
  }
}
