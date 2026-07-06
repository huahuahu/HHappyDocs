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

  @Parameter(title: "widget.moemnt.intent.parameter.participant.title")
  var participant: ParticipantEntity?

  init() {}

  init(participant: ParticipantEntity) {
    self.participant = participant
  }

  static var parameterSummary: some ParameterSummary {
    Summary {
      \.$participant
    }
  }
}

struct ParticipantEntity: AppEntity {
  var id: UUID
  var name: String
  var avatar: UIImage

  static let typeDisplayRepresentation = TypeDisplayRepresentation("widget.moemnt.intent.entity.participant.typeDisplayRepresentation")

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(name)")
  }

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

  static let defaultQuery = ParticipantEntityQuery()
}

@MainActor
struct ParticipantEntityQuery: EntityQuery {
  func entities(for identifiers: [ParticipantEntity.ID]) async throws -> [ParticipantEntity] {
    logger.info("Loading participants for identifiers: \(identifiers)")
    let modelContext = await MomentWidgetUtil.getModelContext()
    let participants = try modelContext.fetch(FetchDescriptor<Participant>(predicate: #Predicate { identifiers.contains($0.uuid) }))
    logger.info("Found \(participants.count) participants for \(identifiers)")
    var result = participants.map { ParticipantEntity(from: $0) }
    if identifiers.contains(where: { uuid in uuid == .null }) {
      result.append(.nonEntity)
    }
    return result
  }

  func suggestedEntities() async throws -> [ParticipantEntity] {
    logger.info("Loading participant to suggest...")
    let modelContext = await MomentWidgetUtil.getModelContext()
    let participants = try modelContext.fetch(MomentWidgetUtil.getParticipantDescriptor())
    logger.info("Found \(participants.count) participants")
    return [.nonEntity] + participants.map { ParticipantEntity(from: $0) }
  }
}

#endif
