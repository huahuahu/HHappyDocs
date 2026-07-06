//
//  MomentParticipantEditView.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/27.
//

import HDiaryModel
import HUIComponent
import SwiftData
import SwiftUI

struct MomentParticipantEditView: View {
  init(allParticipants: [Participant], participants: Binding<[Participant]>) {
    self.allParticipants = allParticipants
    self._participants = participants
  }

  @State private var isEditing = false

  private let allParticipants: [Participant]
  @Binding private var participants: [Participant]
  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 20) {
        ForEach(participants, id: \.uuid) { participant in
          Text(participant.nickName)
            .tagStyle(.selected)
            .foregroundStyle(Color.accentColor)
        }

        Button {
          isEditing = true
        } label: {
          Label {
            Text(DiaryStringKey.edit)
          } icon: {
            Image(systemName: "square.and.pencil")
          }
          .tagStyle(.selected)
        }
        .sheet(isPresented: $isEditing) {
          editView
        }
      }
    }
  }

  private var editView: some View {
    NavigationStack {
      HSelectionView(
        allItems: allParticipants,
        initialItems: participants,
        config: .init(
          title: DiaryStringKey.momentParticipantEditViewNavigationTitle,
          nothingSelectedText: DiaryStringKey.momentParticipantEditViewEmptyString
        )
      ) { newPeople in
        let newUUIDSet = Set(newPeople.map { $0.uuid })
        participants = allParticipants.filter { newUUIDSet.contains($0.uuid) }
      }
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}

extension Participant: @retroactive HSelectionViewItem {
  public var title: String {
    nickName
  }
}

private final class BundleLocation {}

#if DEBUG
  @available(iOS 18.0, *)
  #Preview(traits: .modifier(SampleDataModifier())) {
    @Previewable @Query var participants: [Participant]
    MomentParticipantEditView(
      allParticipants: participants,
      participants: .init(get: {
        return Array(participants.prefix(1))
      }, set: { newModels in
        print("new models \(newModels)")
      })
    )
  }
#endif
