//
//  MomentWidgetIntent.swift
//  HDiaryWidgetExtension
//
//  Created by tigerguo on 2023/7/14.
//

#if os(iOS)

import AppIntents
import HDiaryConstants
import HDiaryWidgetData
import SwiftUI
import UIKit
import WidgetKit

public struct MomentWidgetIntent: WidgetConfigurationIntent {
  public static let title: LocalizedStringResource = LocalizedStringResource(
    "widget.moment.intent.title",
    defaultValue: "Select participant",
    table: "Intents",
    bundle: .main
  )
  public static let description: IntentDescription? = IntentDescription(
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
  public var participantID: String?

  public init() {}

  public init(participantID: String?) {
    self.participantID = participantID
  }

  public init(participant: ParticipantEntity) {
    self.participantID = participant.id.uuidString
  }

  public var selectedParticipantID: UUID? {
    guard let participantID else { return nil }
    return UUID(uuidString: participantID)
  }

  public static var parameterSummary: some ParameterSummary {
    Summary {
      \.$participantID
    }
  }
}

public struct ParticipantEntity: Identifiable {
  public var id: UUID
  public var name: String
  public var avatar: UIImage

  public init(id: UUID, name: String, avatar: UIImage) {
    self.id = id
    self.name = name
    self.avatar = avatar
  }

  public init(from value: WidgetParticipantValue) {
    self.init(
      id: value.uuid,
      name: value.nickName,
      avatar: value.avatarThumbnailData.flatMap(UIImage.init(data:)) ?? Self.defaultAvatar
    )
  }

  @MainActor public static var defaultAvatar: UIImage {
    UIImage(systemName: "person.crop.circle.fill") ?? UIImage()
  }

  @MainActor public static let nonEntity = Self(
    id: .null,
    name: String(localized: LocalizedStringResource(
      "participant.all",
      defaultValue: "All participants",
      table: "Intents",
      bundle: .main
    )),
    avatar: ParticipantEntity.defaultAvatar
  )
}

@MainActor
public struct ParticipantOptionsProvider: DynamicOptionsProvider {
  public nonisolated init() {}

  public func results() async throws -> IntentItemCollection<String> {
    DiagnosticLogging.refreshFromSharedDefaults()
    Log.Widget.intent.log(
      level: DiagnosticLogging.level(for: .info),
      "Loading widget participant options"
    )
    let participants: [WidgetParticipantValue]
    if let dataSource = MomentWidgetUtil.dataSource {
      do {
        participants = try dataSource.fetchParticipants()
      }
      catch {
        Log.Widget.intent.error(
          "Failed to fetch widget participant options: \(error.localizedDescription)"
        )
        participants = []
      }
    }
    else {
      participants = []
    }
    let items = [IntentItem(ParticipantEntity.nonEntity.id.uuidString, title: "\(ParticipantEntity.nonEntity.name)")]
      + participants.map { value in
        IntentItem(value.uuid.uuidString, title: "\(value.nickName)")
      }
    Log.Widget.intent.log(
      level: DiagnosticLogging.level(for: .info),
      "Loaded widget participant options: count=\(participants.count, privacy: .public)"
    )
    return IntentItemCollection(sections: [IntentItemSection(items: items)])
  }
}

#endif
