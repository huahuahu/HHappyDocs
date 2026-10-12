//
//  MomentFilterMenu.swift
//  HDiary
//
//  Created by tigerguo on 2024/12/5.
//

#if os(iOS)

import HDiaryConstants
import SwiftUI

@MainActor struct MomentFilterMenu: View {
  @Binding private var selectedFilter: MomentFilter?

  @ScaledMetric private var selectedFilterHorizontalPadding = 10.0
  @ScaledMetric private var selectedFilterVerticalPadding = 5.0
  @ScaledMetric private var optionIndicatorWidth = 14.0

  init(selectedFilter: Binding<MomentFilter?>) {
    self._selectedFilter = selectedFilter
  }

  var body: some View {
    Menu {
      Button {
        selectedFilter = nil
      } label: {
        optionLabel(DiaryStringKey.Moment.Filter.all, isSelected: selectedFilter == nil)
      }

      ForEach(MomentFilter.allCases) { filter in
        Button {
          selectedFilter = filter
        } label: {
          optionLabel(filter.title, isSelected: selectedFilter == filter)
        }
      }

    } label: {
      if let selectedFilter {
        Text(selectedFilter.title)
          .padding(.horizontal, selectedFilterHorizontalPadding)
          .padding(.vertical, selectedFilterVerticalPadding)
          .background(Color.accentColor.opacity(0.3))
          .clipShape(.capsule(style: .continuous))
      }
      else {
        Label {
          Text(DiaryStringKey.Moment.Filter.filter)
        } icon: {
          Image(hDiarySymbol: .filter)
        }
        .labelStyle(.iconOnly)
      }
    }
  }

  @ViewBuilder
  private func optionLabel(_ title: LocalizedStringResource, isSelected: Bool) -> some View {
    HStack(spacing: 8) {
      Image(hDiarySymbol: .checkmark)
        .opacity(isSelected ? 1 : 0)
        .accessibilityHidden(!isSelected)
        .frame(width: optionIndicatorWidth, alignment: .leading)

      Text(title)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
  }
}

#Preview {
  @Previewable @State var selectedFilter: MomentFilter?

  NavigationStack {
    Group {
      if let selectedFilter = selectedFilter {
        Text(selectedFilter.title)
      }
      else {
        Text(verbatim: "No filter selected")
      }
    }
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        MomentFilterMenu(selectedFilter: $selectedFilter)
      }
    }
  }
}

#endif
