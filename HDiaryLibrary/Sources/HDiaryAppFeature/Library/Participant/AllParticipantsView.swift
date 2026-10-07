//
//  AllParticipantsView.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/25.
//

#if os(iOS)

  import HDiaryModel
  import SwiftData
  import SwiftUI

  struct AllParticipantsView: View {
    @Query(sort: [SortDescriptor(\Participant.nickName, order: .forward)]) private var participants: [Participant]
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
          Label {
            Text(DiaryStringKey.add)
          } icon: {
            Image(systemName: "plus")
          }
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
    let participants: [Participant]
    @ScaledMetric(relativeTo: .body) private var minimumCellWidth = 72.0
    @ScaledMetric(relativeTo: .body) private var columnSpacing = 12.0
    @ScaledMetric(relativeTo: .body) private var rowSpacing = 28.0
    @ScaledMetric(relativeTo: .body) private var sectionSpacing = 28.0

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
        VStack(alignment: .leading, spacing: sectionSpacing) {
          Text(DiaryStringKey.Participant.textForTotalParticipantCount(participants.count))
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .accessibilityAddTraits(.isHeader)

          LazyVGrid(
            columns: [GridItem(.adaptive(minimum: minimumCellWidth), spacing: columnSpacing, alignment: .top)],
            spacing: rowSpacing
          ) {
            ForEach(participants) { participant in
              NavigationLink(value: HDiaryDestination.participant(participant)) {
                ParticipantListItemView(participant: participant)
              }
              .buttonStyle(.plain)
            }
          }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 24)
      }
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

#endif
