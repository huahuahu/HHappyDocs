//
//  TagDetailView.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/20.
//

import HDiaryModel
import SwiftData
import SwiftUI

struct TagDetailView: View {
  @State private var isEditing = false
  let tag: Tag
  var body: some View {
    TageDetailInnerView(tag: tag)
      .toolbar {
        toolbar
      }
      .sheet(isPresented: $isEditing, content: {
        editSheet
      })
  }

  @ToolbarContentBuilder
  private var toolbar: some ToolbarContent {
    ToolbarItem(placement: .primaryAction) {
      Button(action: {
        isEditing = true
      }, label: {
        Label(
          title: { Text(DiaryStringKey.edit) },
          icon: { Image(hDiarySymbol: .edit) }
        )
        .labelStyle(.iconOnly)
      })
    }
  }

  private var editSheet: some View {
    NavigationStack {
      TagEditView(tag: tag, isNewTag: false)
        .navigationTitle(Text(DiaryStringKey.tagEditNavigationTitle))
    }
    .presentationDetents([.medium, .large])
  }
}

private struct TageDetailInnerView: View {
  let tag: Tag
  @ScaledMetric private var contentMargin: CGFloat = 20

  var body: some View {
    ScrollView {
      VStack {
        Text(tag.comments)
          .foregroundStyle(.primary)
          .frame(maxWidth: .infinity, alignment: .leading)
        momentsView
      }
    }
    .contentMargins(contentMargin, for: .scrollContent)
    .navigationTitle(tag.text)
  }

  @ViewBuilder
  private var momentsView: some View {
    if moments.isEmpty {
      NoMomentView()
    }
    else {
      Text(DiaryStringKey.momentLabelWithNumber(moments.count))
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.secondary)
        .font(.subheadline)
        .bold()
        .lineLimit(1)
        .padding(.top)
      LazyVGrid(columns: [.init(.adaptive(minimum: 300))], content: {
        ForEach(moments, id: \.self) { moment in
          MomentItemView(moment: moment)
        }

      })
    }
  }

  private var moments: [Moment] {
    tag.moments?.sorted {
      $0.timestamp > $1.timestamp
    } ?? []
  }
}

#if DEBUG
  #Preview("has moments") {
    let container = HDiaryContainer.inMemoryPreviewContainer
    let tag: Tag = {
      let tag = try? container.mainContext.fetch(FetchDescriptor<Tag>()).first
      tag?.comments = "This is a tag"
      return tag!
    }()

    NavigationStack {
      TagDetailView(tag: tag)
        .modelContainer(container)
    }
  }

  #Preview("No moments") {
    let container = HDiaryContainer.inMemoryPreviewContainer
    let tag: Tag = {
      let tag = try? container.mainContext.fetch(FetchDescriptor<Tag>()).first
      tag?.comments = ""
      return tag!
    }()

    NavigationStack {
      TagDetailView(tag: tag)
        .modelContainer(container)
    }
  }

#endif
