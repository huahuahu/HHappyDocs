//
//  SearchPoemView.swift
//  Libai
//
//  Created by huahuahu on 2022/5/30.
//

import SwiftUI

struct SearchPoemView: View {
  let matchedPoems: [SearchedPoem]
  @State private var selectedReason: SearchMatchReason = .all

  var allReasons: SearchMatchReason {
    var result: SearchMatchReason = []
    for reason in matchedPoems.map(\.matchReason) {
      result = result.union(reason)
    }
    return result
  }

  private var poemsToDisplay: [SearchedPoem] {
    if selectedReason == .all {
      return matchedPoems
    }
    return matchedPoems.filter { poem in
      poem.matchReason.contains(selectedReason)
    }
  }

  var body: some View {
    if !poemsToDisplay.isEmpty {
      HStack {
        Spacer(minLength: 0)
        SearchResultFilterView(allReasons: allReasons, selectedReason: $selectedReason)
        Spacer(minLength: 0)
      }
      .background(Color.primaryBackground)
      .frame(maxWidth: .infinity)
    }
    SearchPoemList(searchedPoems: poemsToDisplay, reason: selectedReason)
  }
}

struct SearchPoemView_Previews: PreviewProvider {
  static var previews: some View {
    SearchPoemView(matchedPoems: [.demo])
  }
}
