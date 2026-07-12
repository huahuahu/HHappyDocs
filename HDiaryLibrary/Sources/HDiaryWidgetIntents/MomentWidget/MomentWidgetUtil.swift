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

@MainActor
public final class MomentWidgetDataSourceProvider {
  public typealias Factory = @MainActor () throws -> MomentWidgetDataSource

  private let factory: Factory
  private var cachedDataSource: MomentWidgetDataSource?

  public init(
    factory: @escaping Factory = {
      MomentWidgetDataSource(
        modelContainer: try WidgetSnapshotContainer.makeReaderContainer()
      )
    }
  ) {
    self.factory = factory
  }

  public var dataSource: MomentWidgetDataSource? {
    if let cachedDataSource {
      return cachedDataSource
    }

    do {
      let dataSource = try factory()
      cachedDataSource = dataSource
      return dataSource
    }
    catch {
      logger.error(
        "Failed to create widget snapshot reader: \(error.localizedDescription, privacy: .public)"
      )
      return nil
    }
  }
}

public enum MomentWidgetUtil {
  @MainActor
  private static let provider = MomentWidgetDataSourceProvider()

  @MainActor
  public static var dataSource: MomentWidgetDataSource? {
    provider.dataSource
  }
}

extension UUID {
  nonisolated public static let null = UUID(uuidString: "00000000-0000-0000-0000-000000000000").unsafelyUnwrapped
}

#endif
