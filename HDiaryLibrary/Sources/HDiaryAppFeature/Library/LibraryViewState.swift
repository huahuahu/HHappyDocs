#if os(iOS)

import Foundation

struct LibraryViewState {
  let tagCount: Int
  let participantCount: Int

  func summary(for entry: LibraryEntry) -> LibraryEntrySummary {
    switch entry {
    case .tag:
      .count(tagCount)
    case .participant:
      .count(participantCount)
    case .chart:
      .localized(DiaryStringKey.chartEntrySummary)
    }
  }
}

#endif
