//
//  SearchEngine.swift
//  HDiary
//
//  Created by tigerguo on 2025/4/16.
//

import Atomics
import Dispatch
import Foundation
import HDiaryConstants
import HDiaryModel
import SwiftData

actor SearchEngine {
  let modelContext: ModelContext

  init(modelContainer: ModelContainer) {
    self.modelContext = ModelContext(modelContainer)
  }

  func searchMoment(for query: String, isCancelled: ManagedAtomic<Bool>) async throws -> [Moment] {
    assert(!Thread.isMainThread, "Should not perform search on main thread")
    if isCancelled.load(ordering: .relaxed) {
      Log.search.debug("Actual search cancelled for \(query) before fetch")
      throw CancellationError()
    }
    let fetchDescriptor = FetchDescriptor<Moment>(sortBy: [.init(\.timestamp, order: .reverse)])
    let moments: [Moment] = try modelContext.fetch(fetchDescriptor)
    if isCancelled.load(ordering: .relaxed) {
      Log.search.debug("Actual search cancelled for \(query) before filter")
      throw CancellationError()
    }
    let matchedMoment = moments.filter { moment in
      moment.content.localizedStandardContains(query)
        || moment.title.localizedStandardContains(query)
    }
    return matchedMoment
  }

  deinit {
    assertionFailure("SearchEngine should not deinit")
  }
}
