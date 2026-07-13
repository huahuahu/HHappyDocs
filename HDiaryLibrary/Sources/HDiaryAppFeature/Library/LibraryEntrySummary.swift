#if os(iOS)

import Foundation

enum LibraryEntrySummary: Equatable {
  case count(Int)
  case localized(LocalizedStringResource)
}

#endif
