//
//  MomentTagEditSection.swift
//  HDiary
//
//  Created by tigerguo on 2023/8/26.
//

#if os(iOS)

import HDiaryModel
import HUIComponent
import SwiftData
import SwiftUI

struct MomentTagEditSection: View {
  init(currentTags: Binding<[Tag]>, allTags: [Tag]) {
    self._currentTags = currentTags
    self.allTags = allTags
  }

  @ScaledMetric private var horizontalPadding = Design.Tag.horizontalPadding
  @ScaledMetric private var verticalPadding = Design.Tag.verticalPadding

  @State private var isEditingTag = false

  @Binding var currentTags: [Tag]
  private let allTags: [Tag]

  var body: some View {
    Section {
      HFlowLayout(
        itemSpace: horizontalPadding,
        rowSpace: verticalPadding,
        horizontalAlignment: .leading
      ) {
        ForEach(currentTags, id: \.uuid) { tag in
          Text(tag.title)
            .tagStyle(.selected)
            .foregroundStyle(Color.accentColor)
        }

        Button {
          isEditingTag = true
        } label: {
          Label {
            Text(DiaryStringKey.edit)
          } icon: {
            Image(systemName: "square.and.pencil")
          }
        }
        .tagStyle(.selected)
        .sheet(isPresented: $isEditingTag) {
          editTagView
        }
      }
    } header: {
      Text(DiaryStringKey.tagEntryLabel)
    }
  }

  private var editTagView: some View {
    NavigationStack {
      HSelectionView(
        allItems: allTags,
        initialItems: currentTags,
        config: .init(
          title: DiaryStringKey.momentTagEditViewNavigationTitle,
          nothingSelectedText: DiaryStringKey.momentTagEditViewEmptyString
        )
      ) { newTags in
        let newTagUUIDSet = Set(newTags.map { $0.id })
        currentTags = allTags.filter { newTagUUIDSet.contains($0.uuid) }
      }
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}

private final class BundleLocation {}

extension Tag: HSelectionViewItem {}

#if DEBUG
  @available(iOS 18.0, *)
  #Preview(traits: .modifier(SampleDataModifier())) {
    @Previewable @Query var tags: [Tag]
    return MomentTagEditSection(
      currentTags: .constant(Array(tags.prefix(2))),
      allTags: tags
    )
  }

#endif

#endif
