//
//  JournalDemoScreen.swift
//  Learn
//
//  Created by tigerguo on 2024/12/20.
//

import SwiftUI

// Why I am doing this?
// https://developer.apple.com/forums/thread/746843?answerId=784514022#784514022
#if canImport(JournalingSuggestions)
  import JournalingSuggestions
#endif

#if canImport(UIKit)
  import UIKit

  let isJournalingSuggestionsAvailable = UIDevice.current.userInterfaceIdiom == .phone
#else
  let isJournalingSuggestionsAvailable = false
#endif

@MainActor
struct JournalDemoScreen: View {
  #if canImport(JournalingSuggestions)
  #endif
  var body: some View {
    #if canImport(JournalingSuggestions)
      if #available(iOS 17.2, *), isJournalingSuggestionsAvailable {
        JournalDemoView()
      }
      else {
        VStack {
          Text(verbatim: "Dynamically not available on this platform.")
        }
      }
    #else
      VStack {
        Text(verbatim: "Statically not available on this platform.")
      }
      .padding()
      .onAppear {
        let caloriesValue = 213.0
        let cal = Measurement(value: caloriesValue, unit: UnitEnergy.kilojoules)
        let calString = cal.formatted(.measurement(width: .abbreviated, usage: .workout))
        Log.common.info("calories \(calString, privacy: .public), \(cal.formatted())")
      }

    #endif
  }
}

#if canImport(JournalingSuggestions)

  @available(iOS 17.2, *)
  struct JournalDemoView: View {
    @State private var suggestion: JournalingSuggestion?
    var body: some View {
      List {
        JournalingSuggestionsPicker {
          Text(verbatim: "Journaling Suggestions")
        } onCompletion: { selectedSuggestion in
          Log.common.info("Journaling suggestion selected: \(selectedSuggestion.title)")
          suggestion = selectedSuggestion
        }

        suggestionView
      }
    }

    @ViewBuilder
    var suggestionView: some View {
      if let suggestion {
        LabeledContent {
          Text(suggestion.title)
        } label: {
          Text(verbatim: "title")
        }

        if let date = suggestion.date {
          LabeledContent {
            Text(date)
          } label: {
            Text(verbatim: "date")
          }
        }
        DisclosureGroup(isExpanded: .constant(true)) {
          ForEach(suggestion.items) { item in
            suggestionItemView(for: item)
          }

        } label: {
          Text(verbatim: "items")
        }
      }
      else {
        EmptyView()
      }
    }

    @ViewBuilder
    private func suggestionItemView(for itemContent: JournalingSuggestion.ItemContent) -> some View {
      JournalSuggestionItemView(item: itemContent)

//        itemContent.content(forType: JournalingSuggestion.)
    }
  }

#endif
#Preview { @MainActor in
  JournalDemoScreen()
}
