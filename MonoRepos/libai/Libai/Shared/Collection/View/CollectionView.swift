//
//  CollectionView.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/2/13.
//

import SwiftUI

struct CollectionView: View {
  @ViewBuilder
  func navigationDestiton(for colletionType: CollectionType) -> some View {
    switch colletionType {
    case .fav:
      FavPoemList()

    case .locationList:
      LocationLoadView()
    case .ageCompare:
      AgeCompareView()
    case .tag:
      TagEntryView()
    case .wordCloud:
      WordCloudView()
    }
  }

  @State private var selectedCategory: CollectionType?
  @State private var columnVisibility =
    NavigationSplitViewVisibility.doubleColumn

  @EnvironmentObject var navigationModel: HNavigationModel

  var body: some View {
    NavigationSplitView(columnVisibility: $columnVisibility) {
      List(CollectionType.allCases, selection: $selectedCategory) { colletionType in
        NavigationLink(value: colletionType) {
          CollectionCell(collectionType: colletionType)
        }
      }
      .navigationTitle(PredefinedString.topic)

    } detail: {
      NavigationStack(path: $navigationModel.collectionPath) {
        if let selectedCategory = selectedCategory {
          navigationDestiton(for: selectedCategory)
            .hNavigationDestination()
        }
        else {
          Text("请选择一个专题")
        }
      }
    }
    .navigationSplitViewStyle(.balanced)
  }
}

struct CollectionView_Previews: PreviewProvider {
  static var previews: some View {
    CollectionView()
      .environmentObject(HNavigationModel())
  }
}
