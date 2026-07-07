//
//  ParticipantAddEditView.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/25.
//

#if os(iOS)

import HDiaryModel
import Observation
import PhotosUI
import SwiftData
import SwiftUI

@MainActor
struct ParticipantAddView: View {
  var body: some View {
    ParticipantAddEditInnerView(
      participant: Participant.create(name: "", nickName: ""),
      isNewParticipant: true
    )
  }
}

@MainActor
struct ParticipantEditView: View {
  let participant: Participant
  var body: some View {
    ParticipantAddEditInnerView(participant: participant, isNewParticipant: false)
  }
}

@MainActor
private struct ParticipantAddEditInnerView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  @State private var taskFinished = false

  init(participant: Participant, isNewParticipant: Bool) {
    self.participant = participant
    self.isNewParticipant = isNewParticipant
  }

  private let participant: Participant
  private let isNewParticipant: Bool

  var body: some View {
    Form {
      AvatarSection(participant: participant)
      nameSection
      nickNameSection
      noteSection
    }
    .toolbar(content: {
      toolbar()
    })
  }

  @ViewBuilder
  private var nameSection: some View {
//    _ = Self._printChanges()
    @Bindable var participant = participant

    Section(header: Text(DiaryStringKey.participantName)) {
      TextField(
        text: $participant.name,
        prompt: Text(DiaryStringKey.participantName)
      ) {
        Text(DiaryStringKey.participantName)
      }
    }
  }

  @ViewBuilder
  private var nickNameSection: some View {
    @Bindable var participant = participant

    Section(header: Text(DiaryStringKey.participantNickName)) {
      TextField(
        text: $participant.nickName,
        prompt: Text(DiaryStringKey.participantNickName)
      ) {
        Text(DiaryStringKey.participantNickName)
      }
    }
  }

  @ViewBuilder
  private var noteSection: some View {
    @Bindable var participant = participant

    Section(header: Text(DiaryStringKey.participantNote)) {
      ZStack(alignment: .leading) {
        Text(participant.note)
          .padding([.leading, .trailing], 5)
          .padding([.top, .bottom], 8)
          .foregroundColor(Color.clear)
        TextEditor(text: $participant.note)
          .autocorrectionDisabled(false)
      }
    }
  }

  @ToolbarContentBuilder
  func toolbar() -> some ToolbarContent {
    ToolbarItem(placement: .confirmationAction) {
      Button(action: {
        if isNewParticipant {
          modelContext.insert(participant)
        }
        dismiss()
        taskFinished = true
      }, label: {
        Text(confirmButtonLabel)
      })
      .sensoryFeedback(trigger: taskFinished, { _, newValue in
        return newValue == true ? .success : nil
      })
    }
  }

  private var confirmButtonLabel: LocalizedStringResource {
    if isNewParticipant {
      DiaryStringKey.add
    }
    else {
      DiaryStringKey.confirm
    }
  }
}

extension ParticipantAddEditInnerView {
  @MainActor
  private struct AvatarSection: View {
    let participant: Participant

    var body: some View {
      //    _ = Self._printChanges()
      @Bindable var participant = participant
      HStack {
        Spacer()
        AvatarSelectionView(image: .init(get: {
          participant.getAvatarImage()
        }, set: { image, _ in
          participant.avatar = image?.heicData()
        }))
        Spacer()
      }
      .listRowBackground(Color.clear)
    }
  }
}

#Preview("Add") {
  NavigationStack {
    ParticipantAddView()
  }
  .modelContainer(HDiaryContainer.inMemoryPreviewContainer)
//    .environment(\.locale, .cnMainland)
}

#Preview("Edit") {
  let container = HDiaryContainer.inMemoryPreviewContainer
  let participant = try? container.mainContext.fetch(FetchDescriptor<Participant>()).first
  NavigationStack {
    ParticipantEditView(participant: participant!)
      .environment(\.locale, .cnMainland)
      .modelContainer(container)
  }
}

#endif
