#if os(iOS)
  @testable import HDiaryAppFeature
  import Testing
  import UIKit

  @MainActor
  struct ParticipantAvatarPreviewTests {
    @Test
    func repeatedTapsPrepareOnlyOnePreviewAndDismissalAllowsReopening() async throws {
      var preparedData: [Data] = []
      let preview = ParticipantAvatarPreview { data in
        preparedData.append(data)
        return URL(filePath: "/avatar-\(preparedData.count).png")
      }
      let original = Data([1])
      preview.begin(data: original)
      let requestID = preview.request?.id
      preview.begin(data: original)
      #expect(preview.request?.id == requestID)
      await preview.prepare()
      let firstURL = try #require(preview.previewURL)
      preview.begin(data: original)
      #expect(preview.request == nil)
      #expect(preparedData == [original])

      // This is the binding change made by Quick Look on dismissal.
      preview.previewURL = nil
      let replacement = Data([2])
      preview.begin(data: replacement)
      await preview.prepare()
      #expect(preview.previewURL != firstURL)
      #expect(preparedData == [original, replacement])
    }

    @Test(.timeLimit(.minutes(1)))
    func sourceChangeIgnoresLatePreparationAndUsesCurrentOriginal() async {
      let gate = PreparationGate()
      var starts = gate.starts.makeAsyncIterator()
      let preview = ParticipantAvatarPreview(prepareFile: gate.prepare)
      preview.begin(data: Data([1]))
      let oldTask = Task { await preview.prepare() }
      _ = await starts.next()

      preview.reset()
      preview.begin(data: Data([2]))
      let newTask = Task { await preview.prepare() }
      _ = await starts.next()
      gate.finish(Data([2]))
      await newTask.value
      let currentURL = preview.previewURL
      gate.finish(Data([1]))
      await oldTask.value

      #expect(currentURL == URL(filePath: "/avatar-2.png"))
      #expect(preview.previewURL == currentURL)
      #expect(!preview.showsError)
    }

    @Test(.timeLimit(.minutes(1)))
    func cancellationNeverPresentsOrShowsAnErrorAndAllowsRetry() async {
      let gate = PreparationGate()
      var starts = gate.starts.makeAsyncIterator()
      let preview = ParticipantAvatarPreview(prepareFile: gate.prepare)
      preview.begin(data: Data([1]))
      let task = Task { await preview.prepare() }
      _ = await starts.next()
      task.cancel()
      gate.finish(Data([1]))
      await task.value

      #expect(preview.previewURL == nil)
      #expect(preview.request == nil)
      #expect(!preview.showsError)
      preview.begin(data: Data([2]))
      #expect(preview.request?.data == Data([2]))
    }

    @Test
    func writeFailureShowsFeedbackAndCanRetryAfterStorageRecovers() async throws {
      let root = temporaryRoot()
      defer { try? FileManager.default.removeItem(at: root) }
      try Data([0]).write(to: root) // A file blocks creation of the preview directory.
      let files = ParticipantAvatarPreviewFiles(root: root)
      let preview = ParticipantAvatarPreview { try await files.prepare($0) }
      let data = imageData()
      preview.begin(data: data)
      await preview.prepare()
      #expect(preview.showsError)
      #expect(preview.previewURL == nil)
      #expect(preview.request == nil)

      try FileManager.default.removeItem(at: root)
      preview.begin(data: data)
      #expect(!preview.showsError)
      await preview.prepare()
      let url = try #require(preview.previewURL)
      #expect(try Data(contentsOf: url) == data)
    }

    @Test(arguments: [false, true])
    func fileKeepsOriginalBytesAndFullResolution(jpeg: Bool) async throws {
      let root = temporaryRoot()
      defer { try? FileManager.default.removeItem(at: root) }
      let files = ParticipantAvatarPreviewFiles(root: root)
      let data = imageData(jpeg: jpeg)
      let thumbnail = try #require(await ParticipantAvatarImage.decode(data, maxPixelSize: 40))
      #expect(thumbnail.cgImage?.width == 40)

      let url = try await files.prepare(data)
      let original = try Data(contentsOf: url)
      #expect(original == data)
      #expect(url.deletingPathExtension().lastPathComponent == "image")
      #expect(url.pathExtension == (jpeg ? "jpeg" : "png"))
      #expect(UIImage(data: original)?.size == CGSize(width: 400, height: 200))
    }

    @Test
    func dismissalAndSourceChangesRetainFilesUntilTheNextSession() async throws {
      let root = temporaryRoot()
      defer { try? FileManager.default.removeItem(at: root) }
      let files = ParticipantAvatarPreviewFiles(root: root)
      let preview = ParticipantAvatarPreview { try await files.prepare($0) }
      let data = imageData()
      preview.begin(data: data)
      await preview.prepare()
      let first = try #require(preview.previewURL)
      preview.previewURL = nil
      let replacement = imageData(color: .red)
      preview.begin(data: replacement)
      await preview.prepare()
      let second = try #require(preview.previewURL)
      preview.reset()
      #expect(first != second)
      #expect(try Data(contentsOf: first) == data)
      #expect(try Data(contentsOf: second) == replacement)

      let unrelated = root.appendingPathComponent("unrelated.txt")
      try Data([1]).write(to: unrelated)
      let nextSession = ParticipantAvatarPreviewFiles(root: root)
      let current = try await nextSession.prepare(data)
      #expect(!FileManager.default.fileExists(atPath: first.path))
      #expect(!FileManager.default.fileExists(atPath: second.path))
      #expect(FileManager.default.fileExists(atPath: unrelated.path))
      #expect(try Data(contentsOf: current) == data)
    }

    @Test
    func reclaimedTemporaryDirectoryIsRecreatedOnTheNextPreview() async throws {
      let root = temporaryRoot()
      defer { try? FileManager.default.removeItem(at: root) }
      let files = ParticipantAvatarPreviewFiles(root: root)
      let data = imageData()
      _ = try await files.prepare(data)
      try FileManager.default.removeItem(at: root)

      let next = try await files.prepare(data)

      #expect(try Data(contentsOf: next) == data)
    }

    @Test
    func invalidDataCannotCreateAPreviewFile() async throws {
      let root = temporaryRoot()
      defer { try? FileManager.default.removeItem(at: root) }
      let files = ParticipantAvatarPreviewFiles(root: root)
      await #expect(throws: ParticipantAvatarPreviewFiles.PreparationError.unsupportedImage) {
        try await files.prepare(Data("not an image".utf8))
      }
      #expect(!FileManager.default.fileExists(atPath: root.path))
    }

    private func temporaryRoot() -> URL {
      FileManager.default.temporaryDirectory.appendingPathComponent("AvatarPreviewTests-\(UUID().uuidString)")
    }

    private func imageData(jpeg: Bool = false, color: UIColor = .blue) -> Data {
      let format = UIGraphicsImageRendererFormat()
      format.scale = 1
      let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 200), format: format)
      let draw: (UIGraphicsImageRendererContext) -> Void = { _ in
        color.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: 400, height: 200))
      }
      return jpeg ? renderer.jpegData(withCompressionQuality: 0.9, actions: draw) : renderer.pngData(actions: draw)
    }
  }

  @MainActor
  private final class PreparationGate {
    let starts: AsyncStream<Data>
    private let continuation: AsyncStream<Data>.Continuation
    private var pending: [Data: CheckedContinuation<URL, Never>] = [:]

    init() {
      (starts, continuation) = AsyncStream.makeStream()
    }

    func prepare(_ data: Data) async -> URL {
      await withCheckedContinuation { pending[data] = $0
        continuation.yield(data)
      }
    }

    func finish(_ data: Data) {
      pending.removeValue(forKey: data)?.resume(returning: URL(filePath: "/avatar-\(data[0]).png"))
    }
  }
#endif
