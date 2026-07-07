//
//  CloudRecord.swift
//  HDiary
//
//  Created by tigerguo on 2024/9/29.
//

#if os(iOS)

import Foundation
import HDiaryModel
import SwiftUI

protocol CloudRecord {
  static var recordType: String { get }
  /// text shown to user about what's the record's name
  static var userDisplayTitle: LocalizedStringResource { get }
  static var nameFieldInCloud: String { get }
}

enum CloudRecordDestination: CaseIterable, Identifiable {
  case moment
  case participant
  case tag

  var id: String {
    "\(self)"
  }

  @MainActor @ViewBuilder
  var destinationView: some View {
    switch self {
    case .moment:
      CloudDataDetailScreen<Moment>()
    case .participant:
      CloudDataDetailScreen<Participant>()
    case .tag:
      CloudDataDetailScreen<Tag>()
    }
  }
}

extension Moment: CloudRecord {
  static var recordType: String { "CD_Moment" }

  static var userDisplayTitle: LocalizedStringResource {
    DiaryStringKey.moments
  }

  static var nameFieldInCloud: String {
    "CD_title"
  }
}

extension Participant: CloudRecord {
  static var recordType: String { "CD_Participant" }
  static var userDisplayTitle: LocalizedStringResource {
    DiaryStringKey.participantEntryLabel
  }

  static var nameFieldInCloud: String {
    "CD_name"
  }
}

extension Tag: CloudRecord {
  static var recordType: String { "CD_Tag" }
  static var userDisplayTitle: LocalizedStringResource {
    DiaryStringKey.tagEntryLabel
  }

  static var nameFieldInCloud: String {
    "CD_text"
  }
}

#endif
