//
//  TagEditView.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/18.
//

#if os(iOS)

import Foundation
import HDiaryModel
import Observation
import SwiftData
import SwiftUI

/// View to edit tag
struct TagEditView: View {
  @Environment(\.dismiss) var dismiss
  @Environment(\.modelContext) var modelContext

  @State private var hasInitialStatePopulated = false
  @State private var taskFinished = false
  // Add tag or edit existing tag
  private let isNewTag: Bool

  init(tag: Tag, isNewTag: Bool) {
    self.isNewTag = isNewTag
    self.tag = tag
  }

  let tag: Tag
  var body: some View {
    Form {
      titleSection
      commentSection
    }
    .toolbar(content: {
      toolBarView
    })
  }

  @ViewBuilder
  private var titleSection: some View {
    @Bindable var tag: Tag = tag
    Section {
      TextField(
        text: $tag.text,
        prompt: Text(DiaryStringKey.tagEditTitlePlaceHolder),
        axis: .vertical
      ) {
        Text(DiaryStringKey.tagEditTitleSectionHeader)
      }
    } header: {
      Text(DiaryStringKey.tagEditTitleSectionHeader)
    }
  }

  @ViewBuilder
  private var commentSection: some View {
    @Bindable var tag: Tag = tag

    Section {
      TextEditor(text: $tag.comments)
        .lineLimit(0)
        .autocorrectionDisabled(false)
    } header: {
      Text(DiaryStringKey.tagEditCommentSectionHeader)
    }
  }

  @ToolbarContentBuilder
  private var toolBarView: some ToolbarContent {
    ToolbarItem(placement: .primaryAction) {
      Button(action: {
        onConfirmTapped()
        dismiss()
        taskFinished = true
      }, label: {
        Text(isNewTag ? DiaryStringKey.tagEditNavigationButtonTitleAdd : DiaryStringKey.confirm)
      })
      .sensoryFeedback(trigger: taskFinished, { _, newValue in
        return newValue == true ? .success : nil
      })
    }
  }

  private func onConfirmTapped() {
    if isNewTag {
      modelContext.insert(tag)
    }
  }
}

#if DEBUG
  #Preview("New tag") {
    Text(verbatim: "back")
      .sheet(isPresented: .constant(true), content: {
        NavigationStack {
          TagEditView(tag: Tag(text: "", comments: ""), isNewTag: true)
            .presentationDetents([.medium, .large])
        }
      })
      .modelContainer(HDiaryContainer.inMemoryEmptyPreviewContainer)
  }

  @available(iOS 18.0, *)
  #Preview("sport", traits: .modifier(SampleDataModifier())) {
    @Previewable @Environment(\.modelContext) var modelContext
    let tag: Tag = {
      let tag = try? modelContext.fetch(FetchDescriptor<Tag>()).first
      tag?.comments = "第一行\n第二 行"
      return tag!
    }()

    Text(verbatim: "back")
      .sheet(isPresented: .constant(true), content: {
        NavigationStack {
          TagEditView(tag: tag, isNewTag: false)
            .presentationDetents([.medium, .large])
        }
      })
  }
#endif

#endif
