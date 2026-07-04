//
//  InteractionListView.swift
//  Learn
//
//  Created by tigerguo on 2023/11/14.
//

import SwiftUI

struct InteractionListView: View {
  var body: some View {
    List(InteractionEntry.allCases) { entry in
      NavigationLink(value: NavigationTarget.interaction(entry: entry)) {
        VStack {
          Text(entry.rawValue)
        }
      }
    }
    .navigationTitle("Interaction")
  }
}

#Preview {
  InteractionListView()
}
