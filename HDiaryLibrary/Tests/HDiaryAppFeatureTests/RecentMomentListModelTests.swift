#if os(iOS)

import Foundation
import HDiaryModel
import SwiftData
import XCTest
@testable import HDiaryAppFeature

@MainActor
final class RecentMomentListModelTests: XCTestCase {
  func testSaveNotificationPostedFromBackgroundContextDoesNotSynchronouslyUpdateMainActorModel() async throws {
    let container = try ModelContainer(for: Moment.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let model = RecentMomentListModel()
    model.updateMode(modelContext: ModelContext(container))
    let threshold = RecentMomentListModel.Constants.showAllMomentThreshold

    let saveFinished = DispatchSemaphore(value: 0)
    let saveResult = LockedResult()

    Thread {
      let modelContext = ModelContext(container)
      do {
        for moment in Moment.getSampleMoments(count: threshold) {
          modelContext.insert(moment)
        }
        try modelContext.save()
        saveResult.set(.success(()))
      }
      catch {
        saveResult.set(.failure(error))
      }
      saveFinished.signal()
    }.start()

    XCTAssertEqual(saveFinished.wait(timeout: .now() + 2), .success)
    try saveResult.get()

    XCTAssertEqual(model.mode, .showAllMoment)

    try await waitForRecentMomentMode(in: model)
  }

  private func waitForRecentMomentMode(in model: RecentMomentListModel) async throws {
    let threshold = RecentMomentListModel.Constants.showAllMomentThreshold
    let deadline = Date().addingTimeInterval(2)
    while Date() < deadline {
      if case let .showRecentMoment(_, count) = model.mode, count == threshold {
        return
      }
      try await Task.sleep(for: .milliseconds(10))
    }
    XCTFail("Expected save notification to update recent moment mode on the main actor")
  }
}

private final class LockedResult: @unchecked Sendable {
  private let lock = NSLock()
  private var result: Result<Void, Error>?

  func set(_ result: Result<Void, Error>) {
    lock.withLock {
      self.result = result
    }
  }

  func get() throws {
    let result = lock.withLock {
      self.result
    }

    try result?.get()
  }
}

#endif
