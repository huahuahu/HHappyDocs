//
//  MomentWidgetIntent.swift
//  HDiaryWidgetExtension
//
//  Created by tigerguo on 2023/7/14.
//

#if os(iOS)

import AppIntents
import HDiaryModel
import OSLog
import SwiftData
import UIKit
import WidgetKit
import SwiftUI

private let logger = Logger(subsystem: "com.tiger.suzhou.hdiary", category: "MomentWidgetIntent")

struct MomentWidgetIntent: WidgetConfigurationIntent {
  static let title: LocalizedStringResource = LocalizedStringResource(
    "widget.moment.intent.title",
    defaultValue: "Select participant",
    table: "Intents",
    bundle: .main
  )
  static let description: IntentDescription? = IntentDescription(
    LocalizedStringResource(
      "widget.moment.intent.description",
      defaultValue: "Select a participant to show their moments",
      table: "Intents",
      bundle: .main
    )
  )

  @Parameter(
    title: LocalizedStringResource(
      "widget.moment.intent.parameter.participant.title",
      defaultValue: "Participant",
      table: "Intents",
      bundle: .main
    ),
    optionsProvider: ParticipantOptionsProvider()
  )
  var participantID: String?

  init() {}

  init(participantID: String?) {
    self.participantID = participantID
  }

  init(participant: ParticipantEntity) {
    self.participantID = participant.id.uuidString
  }

  var selectedParticipantID: UUID? {
    guard let participantID else { return nil }
    return UUID(uuidString: participantID)
  }

  static var parameterSummary: some ParameterSummary {
    Summary {
      \.$participantID
    }
  }
}

struct ParticipantEntity: Identifiable {
  var id: UUID
  var name: String
  var avatar: UIImage

  init(id: UUID, name: String, avatar: UIImage) {
    self.id = id
    self.name = name
    self.avatar = avatar
  }

  init(from participant: Participant) {
    self.init(
      id: participant.uuid,
      name: participant.nickName,
      avatar: participant.getAvatarImage()
    )
  }

  @MainActor static let nonEntity = Self(
    id: .null,
    name: String(localized: LocalizedStringResource(
      "participant.all",
      defaultValue: "All participants",
      table: "Intents",
      bundle: .main
    )),
    avatar: UIImage(resource: .defaultPerson)
  )
}

@MainActor
struct ParticipantOptionsProvider: DynamicOptionsProvider {
  nonisolated init() {}

  func results() async throws -> IntentItemCollection<String> {
    logger.info("Loading participant options...")
    let modelContext = await MomentWidgetUtil.getModelContext()
    let participants = try modelContext.fetch(MomentWidgetUtil.getParticipantDescriptor())
    let items = [IntentItem(ParticipantEntity.nonEntity.id.uuidString, title: "\(ParticipantEntity.nonEntity.name)")]
      + participants.map { participant in
        IntentItem(participant.uuid.uuidString, title: "\(participant.nickName)")
      }
    logger.info("Found \(participants.count) participant options")
    return IntentItemCollection(sections: [IntentItemSection(items: items)])
  }
}

#endif
