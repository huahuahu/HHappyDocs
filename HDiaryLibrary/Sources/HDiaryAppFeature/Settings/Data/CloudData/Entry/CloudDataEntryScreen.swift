//
//  CloudDataEntryScreen.swift
//  HDiary
//
//  Created by tigerguo on 2024/9/29.
//

#if os(iOS)

import CloudKit
import HDiaryModel
import SwiftUI

@MainActor
struct CloudDataEntryScreen: View {
  var body: some View {
    List(CloudRecordDestination.allCases) { destination in
      cell(for: destination)
    }
    .navigationTitle(Text(DiaryStringKey.Data.CloudData.cellLabel))
    .navigationBarTitleDisplayMode(.inline)
  }

  @ViewBuilder
  private func cell(for destination: CloudRecordDestination) -> some View {
    switch destination {
    case .moment:
      NavigationLink(value: HDiaryDestination.cloudDataDetail(for: .moment)) {
        DataEntryCell<Moment>(recordType: Moment.userDisplayTitle)
      }
    case .participant:
      NavigationLink(value: HDiaryDestination.cloudDataDetail(for: .participant)) {
        DataEntryCell<Participant>(recordType: Participant.userDisplayTitle)
      }

    case .tag:
      NavigationLink(value: HDiaryDestination.cloudDataDetail(for: .tag)) {
        DataEntryCell<Tag>(recordType: Tag.userDisplayTitle)
      }
    }
  }
}

#Preview { @MainActor in
  NavigationStack {
    CloudDataEntryScreen()
  }
  .previewEnvironment()
}

#endif
