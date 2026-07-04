//
//  SerchDemoListView.swift
//  Learn
//
//  Created by tigerguo on 2025/1/24.
//

import SwiftUI

extension SearchDemo {
  @MainActor
  struct ListView: View {
    var body: some View {
      List {
        ForEach(SearchDemoEntry.allCases) { entry in
          NavigationLink(value: NavigationTarget.search(entry: entry)) {
            VStack {
              Text(entry.title)
            }
          }
        }
      }
      .navigationTitle(Text(verbatim: "Search Demos"))
    }
  }
}

#Preview(body: { @MainActor in
  NavigationStack {
    SearchDemo.ListView()
  }
})
