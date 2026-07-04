//
//  AIListView.swift
//  Learn
//
//  Created by tigerguo on 2024/11/20.
//

import SwiftUI

extension AIDemo {
  struct AIListView: View {
    var body: some View {
      List(AIDemoEntry.allCases) { entry in
        NavigationLink(value: NavigationTarget.ai(entry: entry)) {
          VStack {
            Text(entry.title)
          }
        }
      }
      .navigationTitle(Entry.aiDemo.title)
    }
  }
}

#Preview {
  AIDemo.AIListView()
}
