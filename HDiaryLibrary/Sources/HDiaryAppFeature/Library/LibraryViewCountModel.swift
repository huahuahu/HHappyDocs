#if os(iOS)

import Combine
import Foundation
import HDiaryConstants
import HDiaryModel
import Observation
import SwiftData

@Observable @MainActor
final class LibraryViewCountModel {
  private(set) var viewState = LibraryViewState(tagCount: 0, participantCount: 0)

  private var modelContext: ModelContext?
  private var cancellables = Set<AnyCancellable>()

  init() {
    NotificationCenter.default.publisher(for: ModelContext.didSave)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.refreshCounts()
      }
      .store(in: &cancellables)
  }

  func updateCounts(modelContext: ModelContext) {
    self.modelContext = modelContext
    refreshCounts()
  }

  private func refreshCounts() {
    guard let modelContext else {
      return
    }

    do {
      viewState = LibraryViewState(
        tagCount: try modelContext.fetchCount(FetchDescriptor<Tag>()),
        participantCount: try modelContext.fetchCount(FetchDescriptor<Participant>())
      )
    }
    catch {
      Log.data.error("Failed to fetch library entry counts: \(error.localizedDescription)")
    }
  }
}

#endif
