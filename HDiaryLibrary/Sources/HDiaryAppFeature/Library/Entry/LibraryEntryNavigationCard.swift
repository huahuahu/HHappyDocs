#if os(iOS)

import Foundation
import SwiftUI

struct LibraryEntryNavigationCard: View {
  let entry: LibraryEntry
  let summary: LocalizedStringResource
  let contentAxis: Axis

  var body: some View {
    NavigationLink(
      value: HDiaryDestination.libraryEntry(entry: entry)
    ) {
      LibraryEntryCard(
        entry: entry,
        summary: summary,
        contentAxis: contentAxis
      )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .buttonStyle(.plain)
  }
}

#endif
