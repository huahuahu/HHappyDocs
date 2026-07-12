//
//  MomentWidgetUtil.swift
//  HDiaryWidgetExtension
//
//  Created by tigerguo on 2023/7/14.
//

#if os(iOS)

import Foundation
import HDiaryWidgetData
import OSLog
import SwiftData

private let logger = Logger(subsystem: "com.tiger.suzhou.hdiary", category: "MomentWidgetUtil")

@MainActor
public final class MomentWidgetDataSource {
  private let modelContainer: ModelContainer

  public init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
  }

  public func fetchParticipants() throws -> [WidgetParticipantValue] {
    let context = ModelContext(modelContainer)
    let descriptor = FetchDescriptor<WidgetParticipantSnapshot>(
      sortBy: [SortDescriptor(\.nickName), SortDescriptor(\.uuid)]
    )
    return try context.fetch(descriptor).map(WidgetParticipantValue.init)
  }

  public func fetchMoments(participantID: UUID) throws -> [WidgetMomentValue] {
    let context = ModelContext(modelContainer)
    let descriptor = FetchDescriptor<WidgetMomentSnapshot>(
      sortBy: [SortDescriptor(\.timestamp, order: .reverse), SortDescriptor(\.uuid)]
    )
    let moments = try context.fetch(descriptor).map(WidgetMomentValue.init)
    guard participantID != .null else {
      return moments
    }
    return moments.filter { $0.participantIDs.contains(participantID) }
  }
}

public enum MomentWidgetUtil {
  @MainActor
  public static let dataSource: MomentWidgetDataSource? = {
    do {
      return MomentWidgetDataSource(
        modelContainer: try WidgetSnapshotContainer.makeReaderContainer()
      )
    }
    catch {
      logger.error(
        "Failed to create widget snapshot reader: \(error.localizedDescription, privacy: .public)"
      )
      return nil
    }
  }()
}

extension UUID {
  nonisolated public static let null = UUID(uuidString: "00000000-0000-0000-0000-000000000000").unsafelyUnwrapped
}

#endif
