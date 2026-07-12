#if os(iOS)

import Foundation

struct LibraryViewState {
  let tagCount: Int
  let participantCount: Int

  func summary(for entry: LibraryEntry) -> LocalizedStringResource {
    switch entry {
    case .tag:
      DiaryStringKey.tagEntrySummary(count: tagCount)
    case .participant:
      DiaryStringKey.participantEntrySummary(count: participantCount)
    case .chart:
      DiaryStringKey.chartEntrySummary
    }
  }
}

#endif
