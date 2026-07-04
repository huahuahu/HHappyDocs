//
//  CreativeWorkView.swift
//  Libai
//
//  Created by huahuahu on 2022/2/5.
//

import SwiftUI

@MainActor
struct CreativeWorkView: View {
  @State private var selectedType: CreativeWorkType = .poems

  @EnvironmentObject var navigationModel: HNavigationModel

  @ViewBuilder
  var content: some View {
    switch selectedType {
    case .poems:
      PoemsView()
    case .prose:
      ProseList()
    case .calligraphy:
      CalligraphyList()
    }
  }

  var body: some View {
    NavigationStack(path: $navigationModel.creativeWorkPath) {
      content
        .navigationTitle(selectedType.title)
        .hNavigationDestination()
        .toolbar {
          ToolbarItem(
            placement: .navigationBarTrailing) {
              Menu("更多") {
                ForEach(CreativeWorkType.allCases) {
                  workType in
                  Button(workType.title) {
                    selectedType = workType
                  }
                }
              }
            }
        }
    }
  }
}

struct CreativeWorkView_Previews: PreviewProvider {
  static var previews: some View {
    CreativeWorkView()
      .environmentObject(HNavigationModel())
  }
}
