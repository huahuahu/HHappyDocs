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

// TODO: Add localiztion
private let logger = Logger(subsystem: "com.tiger.suzhou.hdiary", category: "MomentWidgetIntent")

struct MomentWidgetIntent: WidgetConfigurationIntent {
  static let title: LocalizedStringResource = "widget.moemnt.intent.title"
  static let description: IntentDescription? = IntentDescription("widget.moemnt.intent.IntentDescription")

  @Parameter(title: "widget.moemnt.intent.parameter.participant.title", optionsProvider: ParticipantOptionsProvider())
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

  @MainActor static let nonEntity = Self(id: .null, name: String(localized: LocalizedStringResource(stringLiteral: "participant.all")), avatar: UIImage(resource: .defaultPerson))
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
