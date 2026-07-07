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

  init(selectedFilter: Binding<MomentFilter?>) {
    self._selectedFilter = selectedFilter
  }

  var body: some View {
    Menu {
      Button {
        selectedFilter = nil
      } label: {
        if selectedFilter == nil {
          Label {
            Text(DiaryStringKey.Moment.Filter.all)
          } icon: {
            Image(hDiarySymbol: .checkmark)
          }
        }
        else {
          Text(DiaryStringKey.Moment.Filter.all)
        }
      }

      ForEach(MomentFilter.allCases) { filter in
        Button {
          selectedFilter = filter
        } label: {
          if let selectedFilter = selectedFilter, selectedFilter == filter {
            Label {
              Text(filter.title)
            } icon: {
              Image(hDiarySymbol: .checkmark)
            }
          }
          else {
            Text(filter.title)
          }
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
