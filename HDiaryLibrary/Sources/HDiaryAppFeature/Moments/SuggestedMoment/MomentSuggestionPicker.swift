#if os(iOS) && canImport(JournalingSuggestions)

import HDiaryConstants
import HDiaryModel
import SwiftUI
@preconcurrency import JournalingSuggestions

/// Keeps framework-specific view metadata out of the ordinary add-moment view.
/// Only create this view after checking isJournalingSuggestionsAvailable.
@available(iOS 17.2, *)
struct MomentSuggestionPicker<Content: View>: View {
  let content: Content
  @Binding var isPresented: Bool
  let onSelection: () -> Void
  let onCompletion: (Moment) -> Void

  var body: some View {
    content.journalingSuggestionsPicker(isPresented: $isPresented) { suggestion in
      Log.common.log(level: DiagnosticLogging.level(for: .info), "Journaling suggestion selected: \(suggestion.title)")
      onSelection()
      let moment = await MomentSuggestionUtil.momentFrom(suggestion: suggestion)
      onCompletion(moment)
    }
  }
}

#endif
