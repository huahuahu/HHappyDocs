//
//  AllTagsView.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/18.
//

import HDiaryModel
import SwiftData
import SwiftUI

struct AllTagsView: View {
  @Environment(\.modelContext) private var modelContext
  @Query private var tags: [Tag]
  @State private var isAddingTag = false
  @State private var tagSortOrder: TagSortOrder = .name

  var body: some View {
    List {
      Section {
        ForEach(sortedTags) { tag in
          NavigationLink(value: HDiaryDestination.tag(tag: tag)) {
            TagCell(tag: tag)
          }
        }
        .onDelete(perform: deleteItems)
      } footer: {
        if viewState.shouldShowTotalTagCount {
          totalTagCountView
        }
      }
    }
    .scrollIndicatorsFlash(onAppear: true)
    .scrollIndicatorsFlash(trigger: tags.count)
    .listStyle(.plain)
    .overlay {
      if tags.isEmpty {
        NoTagView()
      }
    }
    .toolbar {
      toolBarView
    }
    .sheet(isPresented: $isAddingTag, content: {
      addTagView
    })
  }

  @ToolbarContentBuilder
  var toolBarView: some ToolbarContent {
    ToolbarItemGroup(placement: .topBarTrailing) {
      if !tags.isEmpty {
        TagSortMenu { newTagSortOrder in
          tagSortOrder = newTagSortOrder
        }
      }
      Button(action: {
        isAddingTag = true
      }) {
        Label(
          title: { Text(DiaryStringKey.addMomentViewTitle) },
          icon: { Image(hDiarySymbol: .plus) }
        )
      }
    }
  }

  private var addTagView: some View {
    NavigationStack {
      TagEditView(tag: Tag(text: ""), isNewTag: true)
        .navigationTitle(Text(DiaryStringKey.tagAddNavigationTitle))
    }
    .presentationDetents([.medium, .large])
  }

  @ViewBuilder
  private var totalTagCountView: some View {
    Text(DiaryStringKey.Tag.textForTotalTagCount(tags.count))
      .foregroundStyle(.secondary)
      .font(.footnote)
      .frame(maxWidth: .infinity, alignment: .center)
  }

  private var sortedTags: [Tag] {
    tagSortOrder.sortTags(tags)
  }

  private var viewState: AllTagsViewState {
    AllTagsViewState(totalTagCount: tags.count)
  }

  private func deleteItems(offsets: IndexSet) {
    withAnimation {
      for index in offsets {
        modelContext.delete(sortedTags[index])
      }
    }
  }
}

#if DEBUG
  #Preview("non-empty") { @MainActor in
//    let container = HDiaryContai/*n*/er.inMemoryPreviewContainer
    return NavigationStack {
      AllTagsView()
        .modelContainer(HDiaryContainer.inMemoryPreviewContainer)
        .navigationTitle(Text(verbatim: "Tags"))
        .toolbarTitleDisplayMode(.inline)
    }
  }

  #Preview("empty") { @MainActor in
    return NavigationStack {
      AllTagsView()
        .modelContainer(HDiaryContainer.inMemoryEmptyPreviewContainer)
        .navigationTitle(Text(verbatim: "Tags"))
        .toolbarTitleDisplayMode(.inline)
    }
  }
#endif
