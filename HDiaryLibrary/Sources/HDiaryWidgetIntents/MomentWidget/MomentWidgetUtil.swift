//
//  MomentWidgetUtil.swift
//  HDiaryWidgetExtension
//
//  Created by tigerguo on 2023/7/14.
//

#if os(iOS)

import Foundation
import HDiaryModel
import SwiftData

public enum MomentWidgetUtil {
  public static func getParticipantDescriptor(fetchLimit: Int? = nil) -> FetchDescriptor<Participant> {
    let sortDescriptor = SortDescriptor<Participant>(\.nickName, order: .forward)
    var fetchDescriptor = FetchDescriptor<Participant>(sortBy: [sortDescriptor])
    if let fetchLimit {
      fetchDescriptor.fetchLimit = fetchLimit
    }
    return fetchDescriptor
  }

  public static func getModelContext() async -> ModelContext {
    let container = await MainActor.run {
      return HDiaryContainer.getCurrentContainer()
    }
    return ModelContext(container)
  }
}

extension UUID {
  nonisolated public static let null = UUID(uuidString: "00000000-0000-0000-0000-000000000000").unsafelyUnwrapped
}

#endif
