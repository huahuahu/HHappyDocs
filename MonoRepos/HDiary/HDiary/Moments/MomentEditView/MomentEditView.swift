//
//  MomentEditView.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/18.
//

import HDiaryConstants
import HDiaryModel
import HUIComponent
import SwiftData
import SwiftUI
import WidgetKit

@MainActor
struct AddMomentView: View {
  @Environment(\.modelContext) private var modelContext
  @Query private var tags: [Tag]
  @Query private var participants: [Participant]
  private let moment: Moment

  init(moment: Moment, onMomentAdded: @escaping (Moment) -> Void) {
    self.moment = moment
    self.onMomentAdded = onMomentAdded
  }

  var onMomentAdded: (Moment) -> Void

  var body: some View {
    MomentEditInnerView(
      onMomentAdded: { moment in
        onMomentAdded(moment)
      },
      moment: moment,
      isNewMoment: true,
      allTags: tags.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending },
      allParticipants: participants.sorted { $0.nickName.localizedStandardCompare($1.nickName) == .orderedAscending }
    )
  }
}

@MainActor
struct EditMomentView: View {
  init(initialMoment: Moment, onMomentAdded: @escaping (Moment) -> Void) {
    self.onMomentAdded = onMomentAdded
    self.initialMoment = initialMoment
  }

  @Query private var tags: [Tag]
  @Query private var participants: [Participant]
  @Environment(\.modelContext) private var modelContext

  let onMomentAdded: (Moment) -> Void
  let initialMoment: Moment

  var body: some View {
    MomentEditInnerView(
      onMomentAdded: { moment in
        onMomentAdded(moment)
      },
      moment: initialMoment,
      isNewMoment: false,
      allTags: tags.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending },
      allParticipants: participants.sorted { $0.nickName.localizedStandardCompare($1.nickName) == .orderedAscending }
    )
    .onAppear {
      // Don't call `increaseVisitCount` here as the timing is incorrect.
      // DetailView -> EditView path, `increaseVisitCount` has been called in DetailView
      initialMoment.lastVisitDate = Date()
    }
  }
}

@MainActor
struct MomentEditInnerView: View {
  fileprivate init(
    onMomentAdded: @escaping (Moment) -> Void,
    moment: Moment,
    isNewMoment: Bool,
    allTags: [Tag],
    allParticipants: [Participant]
  ) {
    self.onMomentAdded = onMomentAdded
    self.moment = moment
    self.isNewMoment = isNewMoment
    self.allTags = allTags
    self.allParticipants = allParticipants
  }

  private var isNewMoment = false
  @State private var taskFinished = false
  @State private var hasInitialized = false
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  var onMomentAdded: (Moment) -> Void
  let moment: Moment
  fileprivate let allTags: [Tag]
  private let allParticipants: [Participant]

  var body: some View {
    @Bindable var moment = moment
    Form {
      Section {
        TextField(
          text: .init(get: {
            moment.title
          }, set: { newTitle in
            moment.updateTitle(newTitle)
          }),
          prompt: Text(DiaryStringKey.addMomentTitleSectionPlaceHolder)
        ) {
          Text(DiaryStringKey.addMomentTitleSection)
        }
        .autocorrectionDisabled(false)
      } header: {
        Text(DiaryStringKey.addMomentTitleSection)
      }
      ratingSection

      Section {
        TextEditor(text: .init(get: {
          moment.content
        }, set: { newContent, _ in
          moment.updateContent(newContent)
        }))
        .lineLimit(0)
        .autocorrectionDisabled(false)
      } header: {
        Text(DiaryStringKey.addMomentContentSection)
      }

      Section {
        DatePicker(selection: .init(get: {
          moment.timestamp
        }, set: { newDate in
          moment.updateTimeStamp(newDate)
        })) {
          Text(DiaryStringKey.addMomentTimeStampLabel)
        }
      } header: {
        Text(DiaryStringKey.addMomentTimeStampSectionHeader)
      }

      tagSection
      participantEditSection
      mediaSection
    }
    .navigationTitle(Text(navigationTitle))
    .toolbar {
      toolBarView
    }
    .onDisappear {
      do {
        try modelContext.save()
      }
      catch {
        Log.data.error("Failed to save moment: \(error)")
      }
    }
  }

  @ToolbarContentBuilder
  private var toolBarView: some ToolbarContent {
    ToolbarItem(placement: .cancellationAction) {
//          Button.cancel()
      Button(role: .cancel) {
        if isNewMoment {
          modelContext.delete(moment)
          try? modelContext.save()
        }
        dismiss()
      } label: {
        Text(DiaryStringKey.Common.cancel)
      }
    }

    ToolbarItem(placement: .primaryAction) {
      Button(action: {
        dismiss()
        onMomentAdded(moment)
        self.taskFinished = true
      }, label: {
        Text(confirmButtonLabel)
      })
      .sensoryFeedback(.success, trigger: taskFinished)
    }
  }

  private var confirmButtonLabel: LocalizedStringResource {
    if isNewMoment {
      return DiaryStringKey.addMomentViewDoneButton
    }
    else {
      return DiaryStringKey.confirm
    }
  }

  @ViewBuilder
  private var ratingSection: some View {
    Section {
      HRatingView(
        model: HRatingModel(onColor: Color.accentColor, canEdit: true),
        rating: .init(get: {
          HRating(rawValue: moment.rating) ?? .none
        }, set: { newRating in
          moment.updateRating(newRating?.rawValue ?? 0)
        })
      )
    } header: {
      Text(DiaryStringKey.momentEditViewRatingSectionHeaderLabel)
    }
  }

  @ViewBuilder
  private var tagSection: some View {
    MomentTagEditSection(currentTags: .init(get: {
      moment.getLocalizedComparedTags() ?? []
    }, set: { tags in
      moment.updateTags(tags)
    }), allTags: allTags)
  }

  private var participantEditSection: some View {
    Section {
      MomentParticipantEditView(
        allParticipants: allParticipants,
        participants: .init(get: {
          moment.participants ?? []
        }, set: { participants in
          moment.updateParticipants(participants)
        })
      )
    } header: {
      Text(DiaryStringKey.participantEntryLabel)
    }
  }

  private var mediaSection: some View {
    Section {
      MomentMediaEditView(
        legacyImages: .init(get: {
          moment.images ?? []
        }, set: { images in
          moment.updateLegacyImages(images)
        }),
        mediaItems: .init(get: {
          moment.mediaItems ?? []
        }, set: { mediaItems in
          moment.updateMedias(mediaItems)
        })
      )
    } header: {
      Text(DiaryStringKey.momentEditViewMediaSectionHeaderLabel)
    }
  }

  private var navigationTitle: LocalizedStringResource {
    if isNewMoment {
      return DiaryStringKey.addMomentViewTitle
    }
    else {
      return DiaryStringKey.editMomentViewTitle
    }
  }
}

#if DEBUG
  #Preview("Add") {
    let container = HDiaryContainer.inMemoryPreviewContainer
    return NavigationStack {
      AddMomentView(moment: Moment.create(timestamp: .now)) { _ in
      }
    }
    .modelContainer(container)
  }

  @available(iOS 18.0, *)
  #Preview("Edit", traits: .modifier(SampleDataModifier())) {
    @Previewable @Query var moments: [Moment]

    return NavigationStack {
      EditMomentView(initialMoment: moments.first!) { _ in
      }
    }
  }

#endif
