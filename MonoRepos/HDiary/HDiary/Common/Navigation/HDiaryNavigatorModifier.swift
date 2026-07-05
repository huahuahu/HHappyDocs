//
//  HDiaryNavigatorModifier.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/18.
//

import Foundation
import HDiaryModel
import SwiftUI
import UniformTypeIdentifiers

@MainActor
struct DiaryNavigatorModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .navigationDestination(for: HDiaryDestination.self) { destination in
        destination.targetView
      }
  }
}

enum HDiaryDestination: Hashable {
  case debugView
  case debugEntry(entry: DebugEntry)
  case rawData(destination: RawDataDestination)
  case about
  case icpNumber
  case helpAndFeedback
  case storageUsage
  case storageByMoment
  case momentStorageDetail(Moment)
  case storageByMedia
  case cloudDataEntry
  case cloudDataDetail(for: CloudRecordDestination)
  case deleteMediaItem(mediaItem: MediaItem)
  case moment(Moment, editEnabled: Bool)
  case libraryEntry(entry: LibraryEntry)
  case tag(tag: Tag)
  case participant(Participant)
  case timeConstrainedMoments(TimeConstrainedMoments)
  case chartEntry(ChartEntry)
  case settingEntry(SettingEntry)
  case allMomentsScreen

  @ViewBuilder @MainActor
  var targetView: some View {
    switch self {
    case .debugView:
      DebugDetailView()
    case .debugEntry(entry: let entry):
      entry.destinationView
    case .rawData(destination: let destination):
      destination.destinationView
    case .about:
      HDiaryAboutView()
    case .icpNumber:
      ICPInfoView()
    case .helpAndFeedback:
      HelpAndFeedbackView()
    case .storageUsage:
      StorageUsageView()
    case .storageByMedia:
      MediaStorageView()
    case .storageByMoment:
      MomentStorageView()
    case .momentStorageDetail(let moment):
      MomentStorageDetailScreen(moment: moment)
    case .cloudDataEntry:
      CloudDataEntryScreen()
    case .cloudDataDetail(for: let cloudDataDestination):
      cloudDataDestination.destinationView
    case .deleteMediaItem(mediaItem: let item):
      MediaItemDeleteView(mediaItem: item)
    case .moment(let moment, editEnabled: let editEnabled):
      MomentDetailView(moment: moment, canEdit: editEnabled)
    case .libraryEntry(entry: let entry):
      LibraryEntryDetailWrapperView(entry: entry)
      #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
      #endif
        .navigationTitle(Text(entry.label))
    case .tag(tag: let tag):
      TagDetailView(tag: tag)
    case .participant(let participant):
      ParticipantDetailView(participant: participant)
    case .timeConstrainedMoments(let item):
      TimeConstrainedMomentListView(timeConstrainedMoments: item)
    case .chartEntry(let entry):
      ChartEntryWrapperView(entry: entry)
    case .settingEntry(let settingEntry):
      settingEntry.targetView
    case .allMomentsScreen:
      AllMomentListScreen()
    }
  }
}

extension View {
  func hDiaryNavigator() -> some View {
    modifier(DiaryNavigatorModifier())
  }
}
