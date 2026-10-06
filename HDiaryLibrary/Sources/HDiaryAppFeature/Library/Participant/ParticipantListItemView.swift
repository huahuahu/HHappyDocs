//
//  ParticipantListItemView.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/25.
//
#if os(iOS)

  import HDiaryModel
  import SwiftUI

  struct ParticipantListItemView: View {
    let participant: Participant
    @ScaledMetric(relativeTo: .body) private var avatarSize = 64.0
    @ScaledMetric(relativeTo: .subheadline) private var labelSpacing = 10.0

    var body: some View {
      VStack(spacing: labelSpacing) {
        ParticipantAvatarView(participant: participant, size: avatarSize)
        Text(participant.displayName.isEmpty ? String(localized: DiaryStringKey.participantEntryLabel) : participant.displayName)
          .font(.subheadline)
          .foregroundStyle(.primary)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .contentShape(Rectangle())
      .accessibilityElement(children: .combine)
    }
  }

#endif
