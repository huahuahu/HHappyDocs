//
//  MomentTimeLineProvider.swift
//  HDiaryWidgetExtension
//
//  Created by tigerguo on 2023/7/14.
//

#if os(iOS)

import Foundation
import HDiaryWidgetData
import HDiaryWidgetIntents
import OSLog
import SwiftUI
import WidgetKit

private let logger = Logger(subsystem: "com.tiger.suzhou.hdiary", category: "MomentTimeLineProvider")

struct MomentTimeLineProvider: AppIntentTimelineProvider {
  // A placeholder view is similar to a preview snapshot, but instead of showing example data to let people see the type of data the widget displays, it shows a generic visual representation with no specific content
  func placeholder(in context: Context) -> MomentEntry {
    MomentEntry(date: Date(), summary: .placeHolder)
  }

  func snapshot(for configuration: MomentWidgetIntent, in context: Context) async -> MomentEntry {
    let participantID = configuration.selectedParticipantID
    let participant = await getParticipant(with: participantID)
    let moments = await getMoments(with: participantID)
    let momentEntry = MomentEntry(date: .now, summary: MomentWidgetSummary(participant: participant, moments: moments))
    if momentEntry.summary.validForSnapshot {
      return momentEntry
    }
    else {
      return MomentEntry(date: .now, summary: .placeHolder)
    }
  }

  func timeline(for configuration: MomentWidgetIntent, in context: Context) async -> Timeline<MomentEntry> {
    let participantID = configuration.selectedParticipantID
    let participant = await getParticipant(with: participantID)
    let moments = await getMoments(with: participantID)

    var entries = [MomentEntry]()
    let momentEntry = MomentEntry(date: .now, summary: MomentWidgetSummary(participant: participant, moments: moments))
    entries.append(momentEntry)

    return Timeline(entries: entries, policy: .after(.now.advanced(by: 60)))
  }

  private func getParticipant(with participantID: UUID?) async -> ParticipantEntity? {
    guard let participantID else {
      return nil
    }
    guard participantID != .null else {
      return .nonEntity
    }

    guard let dataSource = MomentWidgetUtil.dataSource else {
      return nil
    }
    do {
      return try dataSource.fetchParticipants()
        .first { $0.uuid == participantID }
        .map(ParticipantEntity.init(from:))
    }
    catch {
      logger.error(
        "Error when fetching participant for \(participantID.uuidString): \(error.localizedDescription, privacy: .public)"
      )
      return nil
    }
  }

  private func getMoments(with participantID: UUID?) async -> [MomentWidgetSummary.Moment] {
    let participantID = participantID ?? .null
    guard let dataSource = MomentWidgetUtil.dataSource else {
      return []
    }
    do {
      let moments = try dataSource.fetchMoments(participantID: participantID)
      logger.info("Found \(moments.count) Moments for \(participantID.uuidString)")
      return moments.map {
        .init(timeStamp: $0.timestamp, title: $0.title, id: $0.uuid)
      }
    }
    catch {
      logger.error(
        "Error when fetching moment for \(participantID.uuidString): \(error.localizedDescription, privacy: .public)"
      )
      return []
    }
  }
}

struct MomentEntry: TimelineEntry {
  let date: Date
  let summary: MomentWidgetSummary
}

struct MomentWidgetSummary {
  init(participant: ParticipantEntity?, moments: [Self.Moment]) {
    self.participant = participant
    self.moments = moments
  }

  struct Moment: Identifiable {
    let timeStamp: Date
    let title: String
    let id: UUID

    static let demo1 = Self(
      timeStamp: .now,
      title: String(localized: LocalizedStringResource(
        "sampleData.moment1.title",
        defaultValue: "Went hiking with friends",
        table: "Intents",
        bundle: .main
      )),
      id: UUID()
    )
    static let demo2 = Self(
      timeStamp: .now.addingTimeInterval(-60 * 60 * 24 * 10),
      title: String(localized: LocalizedStringResource(
        "sampleData.moment2.title",
        defaultValue: "Family dinner night",
        table: "Intents",
        bundle: .main
      )),
      id: UUID()
    )

    static let demo3 = Self(
      timeStamp: .now.addingTimeInterval(-60 * 60 * 24 * 15),
      title: String(localized: LocalizedStringResource(
        "sampleData.moment3.title",
        defaultValue: "Coffee catch-up",
        table: "Intents",
        bundle: .main
      )),
      id: UUID()
    )
  }

  let participant: ParticipantEntity?
  let moments: [Self.Moment]

  var validForSnapshot: Bool {
    return participant != nil && moments.isEmpty
  }
}

extension MomentWidgetSummary {
  static let placeHolder = MomentWidgetSummary(
    participant: .placeHolder,
    moments: [.demo1, .demo2]
  )

  static let empty = MomentWidgetSummary(
    participant: .placeHolder,
    moments: []
  )
}

extension ParticipantEntity {
  static let placeHolder = ParticipantEntity(
    id: UUID(),
    name: String(localized: LocalizedStringResource(
      "sampleData.participantName",
      defaultValue: "Sample participant",
      table: "Intents",
      bundle: .main
    )),
    avatar: ParticipantEntity.defaultAvatar
  )
}

#endif
