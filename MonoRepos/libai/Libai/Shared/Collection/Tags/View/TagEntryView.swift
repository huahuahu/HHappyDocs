//
//  TagEntryView.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/3/20.
//

import CoreData
import HUIComponent
import SwiftUI

@MainActor
struct TagEntryView: View {
  @ScaledMetric private var itemSpace = 10.0
  @ScaledMetric private var rowSpace = 10.0
  @FetchRequest(sortDescriptors: [SortDescriptor(\.name, order: .forward)], predicate: NSPredicate(format: "isDeletedInCloud == false")) private var cdTags: FetchedResults<CDTag>

  @ViewBuilder
  private var content: some View {
    ScrollView {
      HFlowLayout(itemSpace: itemSpace, rowSpace: rowSpace) {
        ForEach(sortedTags, id: \.self) { tag in
          tagItem(for: tag)
        }
      }
      .padding()
    }
  }

  private func tagItem(for tag: String) -> some View {
    NavigationLink(value: TagKey(tag: tag)) {
      Button {} label: {
        Text(tag)
      }
      .buttonStyle(TagButton(isSelected: false))
      .allowsHitTesting(false)
    }
  }

  private var sortedTags: [String] {
    cdTags.map { $0.name }.sorted {
      $0.chineseCompare($1) == .orderedAscending
    }
  }

  var body: some View {
    content
      .navigationTitle(PredefinedString.tag)
  }
}

struct TagCollectionView_Previews: PreviewProvider {
  static var previews: some View {
    TagEntryView()
  }
}
