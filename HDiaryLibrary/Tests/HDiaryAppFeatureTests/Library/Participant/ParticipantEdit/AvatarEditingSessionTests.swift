#if os(iOS)
  @testable import HDiaryAppFeature
  import HDiaryModel
  import PhotosUI
  import SwiftData
  import SwiftUI
  import Testing
  import UIKit

  @MainActor
  struct AvatarEditingSessionTests {
    @Test
    func loadingAndCancellingNeverChangeOriginalBytes() async throws {
      let participant = Participant.create(name: "Original", nickName: "")
      let original = Data([1, 2, 3])
      participant.avatar = original
      let editor = AvatarEditingSession(loadPhoto: { _ in Self.photo() })
      editor.begin(PhotosPickerItem(itemIdentifier: "photo"))
      await editor.load()
      #expect(editor.crop != nil)
      #expect(participant.avatar == original)
      editor.reset()
      #expect(editor.crop == nil)
      #expect(participant.avatar == original)
      #expect(throws: AvatarEditingSession.Failure.self) {
        try editor.commit(Self.photo(), to: participant)
      }
      #expect(participant.avatar == original)
    }

    @Test
    func samePhotoCanBeSelectedAfterEveryDismissalAndAnotherPhotoCanFollow() async throws {
      let editor = AvatarEditingSession(loadPhoto: { _ in Self.photo() })
      var cropIDs: Set<UUID> = []
      for identifier in ["same", "same", "different", "same"] {
        editor.begin(PhotosPickerItem(itemIdentifier: identifier))
        await editor.load()
        let crop = try #require(editor.crop)
        #expect(cropIDs.insert(crop.id).inserted)
        #expect(editor.request == nil)
        // sheet(item:) clears its binding for both Cancel and interactive dismissal.
        editor.crop = nil
        editor.reset()
      }
    }

    @Test
    func loadFailureCanRetryTheOriginalSelection() async {
      var attempts = 0
      var identifiers: [String?] = []
      let editor = AvatarEditingSession { item in
        attempts += 1
        identifiers.append(item.itemIdentifier)
        if attempts == 1 { throw AvatarEditingSession.Failure.invalidImage }
        return Self.photo()
      }
      editor.begin(PhotosPickerItem(itemIdentifier: "cloud-photo"))
      await editor.load()
      #expect(editor.showsLoadError)
      #expect(editor.crop == nil)
      #expect(editor.request == nil)
      editor.retry()
      #expect(!editor.showsLoadError)
      await editor.load()
      #expect(editor.crop != nil)
      #expect(identifiers == ["cloud-photo", "cloud-photo"])
    }

    @Test
    func encodingFailurePreservesOriginalAndCropForRetry() async throws {
      let participant = Participant.create(name: "Original", nickName: "")
      let original = Data([4, 5])
      participant.avatar = original
      var fail = true
      let editor = AvatarEditingSession(loadPhoto: { _ in Self.photo() }, encode: { fail ? nil : $0.pngData() })
      editor.begin(PhotosPickerItem(itemIdentifier: "photo"))
      await editor.load()
      let crop = try #require(editor.crop)
      #expect(throws: AvatarEditingSession.Failure.self) { try editor.commit(crop.image, to: participant) }
      #expect(participant.avatar == original)
      #expect(editor.crop?.id == crop.id)
      fail = false
      try editor.commit(crop.image, to: participant)
      #expect(participant.avatar == crop.image.pngData())
    }

    @Test(arguments: [false, true])
    func confirmedAvatarSurvivesSavingAndRefetching(newParticipant: Bool) async throws {
      let container = try ModelContainer(
        for: Moment.self, Tag.self, Participant.self, MediaItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
      )
      let participant = Participant.create(name: "Avatar", nickName: "")
      if !newParticipant {
        participant.avatar = Data([7])
        container.mainContext.insert(participant)
        try container.mainContext.save()
      }
      let editor = AvatarEditingSession(loadPhoto: { _ in Self.photo() })
      editor.begin(PhotosPickerItem(itemIdentifier: "photo"))
      await editor.load()
      let image = try #require(editor.crop?.image)
      try editor.commit(image, to: participant)
      if newParticipant { container.mainContext.insert(participant) }
      try container.mainContext.save()
      let saved = try #require(ModelContext(container).fetch(FetchDescriptor<Participant>()).first)
      #expect(saved.avatar == image.pngData())
      #expect(UIImage(data: try #require(saved.avatar)) != nil)
    }

    @Test(.timeLimit(.minutes(1)))
    func lateOldRequestCannotReplaceANewerSelection() async throws {
      let gate = LoadGate()
      var starts = gate.starts.makeAsyncIterator()
      let editor = AvatarEditingSession(loadPhoto: gate.load)
      editor.begin(PhotosPickerItem(itemIdentifier: "old"))
      let oldTask = Task { await editor.load() }
      _ = await starts.next()
      editor.begin(PhotosPickerItem(itemIdentifier: "new"))
      let newTask = Task { await editor.load() }
      _ = await starts.next()
      let current = Self.photo()
      gate.finish("new", image: current)
      await newTask.value
      let cropID = try #require(editor.crop?.id)
      gate.finish("old", image: Self.photo())
      await oldTask.value
      #expect(editor.crop?.id == cropID)
      #expect(editor.crop?.image === current)
    }

    @Test(.timeLimit(.minutes(1)), arguments: [false, true])
    func cancellationIgnoresLateResults(taskCancellation: Bool) async {
      let gate = LoadGate()
      var starts = gate.starts.makeAsyncIterator()
      let editor = AvatarEditingSession(loadPhoto: gate.load)
      editor.begin(PhotosPickerItem(itemIdentifier: "cancelled"))
      let task = Task { await editor.load() }
      _ = await starts.next()
      if taskCancellation {
        task.cancel()
      }
      else {
        editor.reset()
      }
      gate.finish("cancelled", image: Self.photo())
      await task.value
      #expect(editor.crop == nil)
      #expect(editor.request == nil)
      #expect(!editor.showsLoadError)
    }

    private static func photo() -> UIImage {
      UIGraphicsImageRenderer(size: CGSize(width: 64, height: 64)).image { context in
        UIColor.systemOrange.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 64, height: 64))
      }
    }

    @MainActor
    private final class LoadGate {
      let starts: AsyncStream<String>
      private let continuation: AsyncStream<String>.Continuation
      private var pending: [String: CheckedContinuation<UIImage, Never>] = [:]

      init() { (starts, continuation) = AsyncStream.makeStream() }

      func load(_ item: PhotosPickerItem) async -> UIImage {
        let identifier = item.itemIdentifier ?? ""
        return await withCheckedContinuation { callback in
          pending[identifier] = callback
          continuation.yield(identifier)
        }
      }

      func finish(_ identifier: String, image: UIImage) {
        let callback = pending.removeValue(forKey: identifier)
        #expect(callback != nil)
        callback?.resume(returning: image)
      }
    }
  }
#endif
