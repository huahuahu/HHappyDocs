//
//  ParticipantDetailView.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/25.
//

#if os(iOS)

import HDiaryConstants
import HDiaryModel
import SwiftData
import SwiftUI

struct ParticipantDetailView: View {
  let participant: Participant

  @State private var isEditing = false

  var body: some View {
    ParticipantDetailInnerView(participant: participant)
      .navigationTitle(participant.nickName)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar(content: {
        toolbar
      })
      .sheet(isPresented: $isEditing, content: {
        NavigationStack {
          ParticipantEditView(participant: participant)
        }
      })
  }

  @ToolbarContentBuilder
  var toolbar: some ToolbarContent {
    ToolbarItem(placement: .primaryAction) {
      Button(action: {
        isEditing = true
      }, label: {
        Image(systemName: "pencil")
          .font(.callout)
          .fontWeight(.semibold)
      })
    }
  }
}

private struct ParticipantDetailInnerView: View {
  let participant: Participant

  @ScaledMetric(relativeTo: .body) private var avatarSize = 64.0
  @ScaledMetric private var spacing = 20

  var body: some View {
    List {
      profileSection
      momentSection
      deleteSection
    }
  }

  @ViewBuilder
  private var profileSection: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .top, spacing: spacing) {
        ParticipantAvatarView(
          participant: participant,
          size: avatarSize,
          supportsPreview: true
        )
        VStack(alignment: .leading) {
          Text(participant.nickName)
            .font(.title2)
            .fontWeight(.bold)
          Text(participant.name)
        }

        Spacer()
      }
    }
    if !participant.note.isEmpty {
      Section {
        Text(participant.note)
          .font(.callout)
      } header: {
        Text(DiaryStringKey.participantNote)
      }
    }
  }

  @ViewBuilder
  private var momentSection: some View {
    if !moments.isEmpty {
      Section {
        ForEach(moments) { moment in
          MomentNavigationLink(moment: moment) {
            HStack {
              Text(moment.title)
            }
          }
        }
      } header: {
        Text(DiaryStringKey.moments)
      }
    }
  }

  private var moments: [Moment] {
    participant.moments?.sorted { $0.timestamp > $1.timestamp } ?? []
  }

  private var deleteSection: some View {
    Section {
      ParticipantDeleteButton(participant: participant)
    }
  }
}

private struct ParticipantDeleteButton: View {
  let participant: Participant
  @State private var isPresentingDeleteAlert = false
  @Environment(\.modelContext) private var modelContext
  @Environment(NavigationStore.self) private var navigationStore

  var body: some View {
    Button(role: .destructive) {
      isPresentingDeleteAlert = true
    } label: {
      Label {
        Text(DiaryStringKey.Common.delete)
      } icon: {
        Image(hDiarySymbol: .trash)
          .foregroundStyle(.red)
      }
    }
    .alert(isPresented: $isPresentingDeleteAlert) {
      Alert(
        title: Text(DiaryStringKey.Common.confirmDelete),
        message: Text(DiaryStringKey.Participant.messageWhenDeletingParticipant(with: participant.nickName)),
        primaryButton: .destructive(Text(DiaryStringKey.Common.delete)) {
          deleteParticipant()
        },
        secondaryButton: .cancel()
      )
    }
  }

  private func deleteParticipant() {
    Log.data.log(level: DiagnosticLogging.level(for: .info), "Deleting participant: \(participant.uuid)")
    modelContext.delete(participant)
    do {
      try modelContext.save()
      Log.data.log(level: DiagnosticLogging.level(for: .info), "Participant deleted: \(participant.uuid)")
    }
    catch {
      Log.data.error("Failed to delete participant \(participant.uuid): \(error)")
    }

    if case let .participant(lastParticipant) = navigationStore.path.last,
       lastParticipant == participant {
      Log.common.log(level: DiagnosticLogging.level(for: .info), "Remove last participant from navigation store")
      navigationStore.path.removeLast()
    }
  }
}

#if DEBUG
  #Preview { @MainActor in
    let container = HDiaryContainer.inMemoryPreviewContainer
    let participant = try? container.mainContext.fetch(FetchDescriptor<Participant>()).first

    return NavigationStack {
      ParticipantDetailView(participant: participant!)
        .navigationTitle(Text(verbatim: "Demo"))
        .navigationBarTitleDisplayMode(.inline)
    }
    .previewEnvironment()
    .environment(NavigationStore())
    .modelContainer(container)
  }

#endif

#endif
