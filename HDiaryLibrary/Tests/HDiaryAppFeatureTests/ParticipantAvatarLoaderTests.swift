#if os(iOS)
  @testable import HDiaryAppFeature
  import Testing
  import UIKit

  @MainActor
  struct ParticipantAvatarLoaderTests {
    private typealias Request = ParticipantAvatarLoader.Request

    @Test
    func newViewUsesCachedPhotoBeforeItsTaskStarts() async {
      let photo = UIImage()
      var decodeCount = 0
      let store = ParticipantAvatarImageStore { _, _ in
        decodeCount += 1
        return photo
      }
      let request = makeRequest(data: Data([1]))
      let listLoader = ParticipantAvatarLoader(store: store)
      guard case .loading = listLoader.presentation(for: request) else {
        Issue.record("An undecoded photo must not display a name initial")
        return
      }
      await listLoader.load(request)

      let detailLoader = ParticipantAvatarLoader(store: store)
      expectPhoto(photo, data: request.data, in: detailLoader.presentation(for: request))
      await detailLoader.load(request)
      await listLoader.load(request)
      #expect(decodeCount == 1)
    }

    @Test(arguments: [nil, Data([0])] as [Data?])
    func absentOrInvalidPhotoUsesStablePlaceholder(data: Data?) async {
      var decodeCount = 0
      let store = ParticipantAvatarImageStore { _, _ in
        decodeCount += 1
        return nil
      }
      let request = makeRequest(data: data)
      let loader = ParticipantAvatarLoader(store: store)
      await loader.load(request)
      let newLoader = ParticipantAvatarLoader(store: store)
      guard case .placeholder = newLoader.presentation(for: request) else {
        Issue.record("A missing or rejected image must show the name initial")
        return
      }
      await newLoader.load(request)
      #expect(decodeCount == (data == nil ? 0 : 1))
    }

    @Test(.timeLimit(.minutes(1)))
    func replacementKeepsPhotoAndLateResultCannotReplaceLatestPhoto() async {
      let gate = DecodeGate()
      var starts = gate.requests.makeAsyncIterator()
      let store = ParticipantAvatarImageStore(decode: gate.decode)
      let loader = ParticipantAvatarLoader(store: store)
      let original = makeRequest(data: Data([1]))
      let originalPhoto = UIImage()
      let initialLoad = Task { await loader.load(original) }
      _ = await starts.next()
      gate.finish(Data([1]), with: originalPhoto)
      await initialLoad.value

      let replacement = makeRequest(data: Data([2]), participantID: original.participantID)
      let slowLoad = Task { await loader.load(replacement) }
      _ = await starts.next()
      expectPhoto(originalPhoto, data: original.data, in: loader.presentation(for: replacement))

      let latest = makeRequest(data: Data([3]), participantID: original.participantID)
      let latestPhoto = UIImage()
      let latestLoad = Task { await loader.load(latest) }
      _ = await starts.next()
      gate.finish(Data([3]), with: latestPhoto)
      await latestLoad.value
      gate.finish(Data([2]), with: UIImage())
      await slowLoad.value

      // An uncached next request exposes the retained photo, not just a cache hit.
      let next = makeRequest(data: Data([4]), participantID: original.participantID)
      expectPhoto(latestPhoto, data: latest.data, in: loader.presentation(for: next))
    }

    @Test
    func deletionAndParticipantChangeNeverReusePreviousPersonsPhoto() async {
      let store = ParticipantAvatarImageStore { _, _ in UIImage() }
      let loader = ParticipantAvatarLoader(store: store)
      let original = makeRequest(data: Data([1]))
      await loader.load(original)

      let otherPerson = makeRequest(data: Data([2]))
      guard case .loading = loader.presentation(for: otherPerson) else {
        Issue.record("Another participant must not inherit the previous photo")
        return
      }
      let deleted = makeRequest(data: nil, participantID: original.participantID)
      guard case .placeholder = loader.presentation(for: deleted) else {
        Issue.record("Deleting a photo must show the initial immediately")
        return
      }
      await loader.load(deleted)
      let replacement = makeRequest(data: Data([3]), participantID: original.participantID)
      guard case .loading = loader.presentation(for: replacement) else {
        Issue.record("A deleted photo must not reappear while loading a replacement")
        return
      }
    }

    @Test(.timeLimit(.minutes(1)))
    func cancellationDoesNotCacheAPermanentPlaceholder() async {
      let gate = DecodeGate()
      var starts = gate.requests.makeAsyncIterator()
      let store = ParticipantAvatarImageStore(decode: gate.decode)
      let loader = ParticipantAvatarLoader(store: store)
      let data = Data([1])
      let request = makeRequest(data: data)
      let cancelledLoad = Task { await loader.load(request) }
      _ = await starts.next()
      cancelledLoad.cancel()
      gate.finish(data, with: nil)
      await cancelledLoad.value
      #expect(store.cachedImage(for: data, maxPixelSize: request.maxPixelSize) == nil)

      let retry = Task { await loader.load(request) }
      _ = await starts.next()
      let photo = UIImage()
      gate.finish(data, with: photo)
      await retry.value
      expectPhoto(photo, data: data, in: loader.presentation(for: request))
    }

    @Test
    func largerAvatarUpgradesResolutionWhileKeepingVisiblePhoto() async {
      var decodedSizes: [Int] = []
      let photo = UIImage()
      let store = ParticipantAvatarImageStore { _, size in
        decodedSizes.append(size)
        return photo
      }
      let loader = ParticipantAvatarLoader(store: store)
      let small = makeRequest(data: Data([1]))
      await loader.load(small)
      let large = Request(participantID: small.participantID, data: small.data, maxPixelSize: 384)
      expectPhoto(photo, data: small.data, in: loader.presentation(for: large))
      await loader.load(large)
      let newLoader = ParticipantAvatarLoader(store: store)
      await newLoader.load(small)
      #expect(decodedSizes == [192, 384])
    }

    private func makeRequest(data: Data?, participantID: UUID = UUID()) -> Request {
      Request(participantID: participantID, data: data, maxPixelSize: 192)
    }

    private func expectPhoto(
      _ expected: UIImage,
      data expectedData: Data?,
      in presentation: ParticipantAvatarLoader.Presentation,
      sourceLocation: SourceLocation = #_sourceLocation
    ) {
      guard case let .image(image, data) = presentation else {
        Issue.record("Expected a visible photo", sourceLocation: sourceLocation)
        return
      }
      #expect(image === expected, sourceLocation: sourceLocation)
      #expect(data == expectedData, sourceLocation: sourceLocation)
    }

    @MainActor
    private final class DecodeGate {
      let requests: AsyncStream<Data>
      private let started: AsyncStream<Data>.Continuation
      private var pending: [Data: CheckedContinuation<UIImage?, Never>] = [:]

      init() {
        (requests, started) = AsyncStream.makeStream()
      }

      func decode(_ data: Data, maxPixelSize: Int) async -> UIImage? {
        await withCheckedContinuation { continuation in
          pending[data] = continuation
          started.yield(data)
        }
      }

      func finish(_ data: Data, with image: UIImage?) {
        let continuation = pending.removeValue(forKey: data)
        #expect(continuation != nil)
        continuation?.resume(returning: image)
      }
    }
  }
#endif
