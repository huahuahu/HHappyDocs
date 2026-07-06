//
//  ParticipantListItemView.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/25.
//
#if os(iOS)

import HDiaryModel
import HUIComponent
import SwiftUI

struct ParticipantListItemView: View {
  let participant: Participant
  @ScaledMetric private var size = Design.Avatar.size

  var body: some View {
    VStack {
      AvatarImageView(size: size, image: participant.getAvatarImage())
      Text(participant.nickName)
        .lineLimit(0)
        .bold()
    }
  }
}

#Preview {
  let container = HDiaryContainer.inMemoryPreviewContainer
  return NavigationStack {
    ScrollView {
      HFlowLayout(itemSpace: 20, rowSpace: 20, horizontalAlignment: .center) {
        ForEach(Participant.getSampleParticipants()) { p in
          ParticipantListItemView(participant: p)
        }
      }
      .padding()
    }
    .navigationTitle(Text(verbatim: "Demo"))
    .navigationBarTitleDisplayMode(.inline)
    .modelContainer(container)
  }
}

#endif
