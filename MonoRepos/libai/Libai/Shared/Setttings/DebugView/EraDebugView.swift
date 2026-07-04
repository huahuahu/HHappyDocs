//
//  EraDebugView.swift
//  Libai
//
//  Created by tigerguo on 2024/2/29.
//

import LibaiModel
import SwiftData
import SwiftUI

@MainActor
struct EraDebugView: View {
  @FetchRequest(sortDescriptors: [SortDescriptor(\.title, order: .forward)]) private var poems: FetchedResults<CDPoem>

  var body: some View {
    List {
      ForEach(poems) { poem in

        Text("\(poem.title)")
      }
    }
    .onAppear {
      print("eras \(poems.count)")
    }
  }
}

#Preview {
  EraDebugView()
}
