//
//  ContentView.swift
//  Learn
//
//  Created by tigerguo on 2023/4/9.
//

import SwiftUI

struct ContentView: View {
  @State private var path: [NavigationTarget] = [
    //    .entry(entry: .search),
//    .search(entry: .indexSwiftData),

//    .interaction(entry: .journalSuggestionDemo),
//    .mediaLearn(item: .checkMediaMetadata),
//    .calendar(entry: .calendarViewUIKit),

    .entry(entry: .swiftUIComponent),
    .swiftUIDemo(entry: .alertEnvironment),
  ]
  var body: some View {
    NavigationStack(path: $path) {
      List {
        ForEach(Entry.allCases) { entry in
          NavigationLink(value: NavigationTarget.entry(entry: entry)) {
            VStack(alignment: .leading, spacing: 10) {
              Text(entry.title)
                .font(.headline)
                .foregroundStyle(.primary)
              Text(entry.subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
            }
          }
        }
      }
      .withNavigator()
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
