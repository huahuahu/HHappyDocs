//
//  AIEntry.swift
//  Learn
//
//  Created by tigerguo on 2024/11/20.
//

import Foundation
import SwiftUI

enum AIDemo {}

extension AIDemo {
  enum AIDemoEntry: CaseIterable, Identifiable, Hashable {
    case summary
    case imageAI // New entry

    var id: Self {
      self
    }

    var title: String {
      switch self {
      case .summary:
        return "AI Summary"
      case .imageAI: // New entry title
        return "Image AI"
      }
    }

    @MainActor
    @ViewBuilder var entryView: some View {
      switch self {
      case .summary:
        SummaryDemoView()
      case .imageAI: // New entry view
        ImageAIDemoView()
      }
    }
  }
}
