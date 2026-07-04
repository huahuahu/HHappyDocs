//
//  AllParticipantsView.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/25.
//

import HDiaryModel
import HUIComponent
import SwiftData
import SwiftUI

struct AllParticipantsView: View {
  @Query(sort: [SortDescriptor(
    \Participant.nickName,
    order:
    .forward
  )]) private var participants: [Participant]
  @State private var isAdding = false
  var body: some View {
    AllParticipantsInnerView(participants: participants)
      .toolbar(content: {
        toolBarView
      })
      .sheet(isPresented: $isAdding, content: {
        presentedAddView
      })
  }

  @ToolbarContentBuilder
  private var toolBarView: some ToolbarContent {
    ToolbarItem(placement: .primaryAction) {
      Button(action: {
        isAdding = true
      }, label: {
        Text(DiaryStringKey.add)
      })
    }
  }

  private var presentedAddView: some View {
    NavigationStack {
      ParticipantAddView()
        .navigationBarTitleDisplayMode(.inline)
    }
  }
}

private struct AllParticipantsInnerView: View {
  init(participants: [Participant]) {
    self.participants = participants
  }

  @ScaledMetric private var itemSpace = 20.0
  @ScaledMetric private var rowSpace = 20.0
  let participants: [Participant]
  var body: some View {
    if participants.isEmpty {
      emptyContentView
    }
    else {
      nonEmptyContentView
    }
  }

  private var nonEmptyContentView: some View {
    ScrollView {
      HFlowLayout(itemSpace: itemSpace, rowSpace: itemSpace, horizontalAlignment: .leading) {
        ForEach(participants) { participant in
          NavigationLink(value: HDiaryDestination.participant(participant)) {
            ParticipantListItemView(participant: participant)
          }
        }
      }
    }
    .padding()
  }

  private var emptyContentView: some View {
    ContentUnavailableView {
      Label(
        title: { Text(DiaryStringKey.participantEmptyViewLabel) },
        icon: { Image(systemName: "person") }
      )
    } description: {
      Text(DiaryStringKey.participantEmptyViewDescription)
    }
  }
}

#Preview("empty") {
  NavigationStack {
    AllParticipantsView()
      .navigationBarTitleDisplayMode(.inline)
      .navigationTitle(Text(verbatim: "Demo"))
  }
  .modelContainer(HDiaryContainer.inMemoryEmptyPreviewContainer)
}

#Preview("none-empty") {
  NavigationStack {
    AllParticipantsView()
      .navigationBarTitleDisplayMode(.inline)
      .navigationTitle(Text(verbatim: "Demo"))
      .modelContainer(HDiaryContainer.inMemoryPreviewContainer)
  }
}
