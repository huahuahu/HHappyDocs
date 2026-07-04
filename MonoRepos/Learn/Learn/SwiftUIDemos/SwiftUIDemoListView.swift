//
//  SwiftUIDemoListView.swift
//  Learn
//
//  Created by tigerguo on 2024/11/20.
//

import SwiftUI

extension SwiftUIDemo {
  @MainActor struct ListView: View {
    var body: some View {
      List(SwiftUIDemoEntry.allCases) { entry in
        NavigationLink(value: NavigationTarget.swiftUIDemo(entry: entry)) {
          VStack {
            Text(entry.title)
          }
        }
      }
      .navigationTitle(Entry.swiftUIComponent.title)
    }
  }
}

#Preview {
  SwiftUIDemo.ListView()
}
