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

enum MomentWidgetUtil {
  static func getParticipantDescriptor(fetchLimit: Int? = nil) -> FetchDescriptor<Participant> {
    let sortDescriptor = SortDescriptor<Participant>(\.nickName, order: .forward)
    var fetchDescriptor = FetchDescriptor<Participant>(sortBy: [sortDescriptor])
    if let fetchLimit {
      fetchDescriptor.fetchLimit = fetchLimit
    }
    return fetchDescriptor
  }

  static func getModelContext() async -> ModelContext {
    let container = await MainActor.run {
      return HDiaryContainer.iCloudContainer
    }
    return ModelContext(container)
  }
}

extension UUID {
  static let null = UUID(uuidString: "00000000-0000-0000-0000-000000000000").unsafelyUnwrapped
}

#endif
