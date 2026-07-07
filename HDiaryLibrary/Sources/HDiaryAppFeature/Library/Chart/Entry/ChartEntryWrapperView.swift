//
//  ChartEntryWrapperView.swift
//  HDiary
//
//  Created by tigerguo on 2023/9/3.
//

#if os(iOS)

import HDiaryModel
import SwiftUI

struct ChartEntryWrapperView: View {
  let entry: ChartEntry
  var body: some View {
    switch entry {
    case .rating:
      MomentRatingPieChartView()
    case .tag:
      TagChartView()
    }
  }
}

#Preview("English") {
  NavigationStack {
    ChartEntryWrapperView(entry: .rating)
      .modelContainer(HDiaryContainer.inMemoryPreviewContainer)
      .environment(\.locale, .en)
  }
}

#Preview("中文") {
  ChartEntryWrapperView(entry: .rating)
    .modelContainer(HDiaryContainer.inMemoryPreviewContainer)
    .environment(\.locale, .cnMainland)
}

#endif
