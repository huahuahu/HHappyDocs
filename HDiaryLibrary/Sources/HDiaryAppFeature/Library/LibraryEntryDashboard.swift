#if os(iOS)

import SwiftUI

struct LibraryEntryDashboard: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @ScaledMetric(relativeTo: .body) private var minimumCardWidth: CGFloat = 104
  @ScaledMetric(relativeTo: .body) private var cardSpacing: CGFloat = 12

  let viewState: LibraryViewState

  var body: some View {
    if LibraryEntryLayoutPolicy.forcesSingleColumn(for: dynamicTypeSize) {
      singleColumnLayout
    }
    else {
      ViewThatFits(in: .horizontal) {
        threeColumnLayout
        singleColumnLayout
      }
    }
  }

  private var threeColumnLayout: some View {
    Grid(horizontalSpacing: cardSpacing) {
      GridRow(alignment: .top) {
        ForEach(LibraryEntry.allCases) { entry in
          LibraryEntryNavigationCard(
            entry: entry,
            summary: viewState.summary(for: entry),
            contentAxis: .vertical
          )
          .frame(
            minWidth: minimumCardWidth,
            idealWidth: minimumCardWidth,
            maxWidth: .infinity,
            maxHeight: .infinity
          )
        }
      }
    }
    .frame(maxWidth: .infinity)
  }

  private var singleColumnLayout: some View {
    VStack(spacing: cardSpacing) {
      ForEach(LibraryEntry.allCases) { entry in
        LibraryEntryNavigationCard(
          entry: entry,
          summary: viewState.summary(for: entry),
          contentAxis: .horizontal
        )
      }
    }
    .frame(maxWidth: .infinity)
  }
}

#if DEBUG

#Preview("Three columns") {
  NavigationStack {
    LibraryEntryDashboard(
      viewState: LibraryViewState(tagCount: 3, participantCount: 7)
    )
    .padding(16)
  }
  .frame(width: 390, height: 360)
}

#Preview("Single column - narrow") {
  NavigationStack {
    LibraryEntryDashboard(
      viewState: LibraryViewState(tagCount: 0, participantCount: 0)
    )
    .padding(16)
  }
  .frame(width: 320, height: 600)
}

#Preview("Single column - accessibility") {
  NavigationStack {
    LibraryEntryDashboard(
      viewState: LibraryViewState(tagCount: 12, participantCount: 9)
    )
    .padding(16)
  }
  .environment(\.dynamicTypeSize, .accessibility3)
  .frame(width: 720, height: 800)
}

#endif

#endif
