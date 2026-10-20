#if os(iOS)
  import HDiaryConstants
  import HDiaryModel
  import Observation
  import PhotosUI
  import SwiftUI
  import UIKit

  /// Selected photos stay here until a valid crop has been encoded successfully.
  @Observable
  final class AvatarEditingSession {
    struct Request {
      let id = UUID()
      let item: PhotosPickerItem
    }

    struct Crop: Identifiable {
      let id = UUID()
      let image: UIImage
    }

    enum Failure: Error {
      case invalidImage, encodingFailed, noPendingCrop
    }

    private(set) var request: Request?
    var crop: Crop?
    var showsLoadError = false
    private var retryItem: PhotosPickerItem?
    private let loadPhoto: @MainActor (PhotosPickerItem) async throws -> UIImage
    private let encode: @MainActor (UIImage) -> Data?

    init(
      loadPhoto: @escaping @MainActor (PhotosPickerItem) async throws -> UIImage = AvatarEditingSession.loadPhoto,
      encode: @escaping @MainActor (UIImage) -> Data? = { $0.pngData() }
    ) {
      self.loadPhoto = loadPhoto
      self.encode = encode
    }

    static func loadPhoto(_ item: PhotosPickerItem) async throws -> UIImage {
      let data = try await item.loadTransferable(type: Data.self)
      try Task.checkCancellation()
      // Bound decoded memory while retaining enough pixels for the final avatar.
      guard let image = await ParticipantAvatarImage.decode(data, maxPixelSize: 2048) else {
        try Task.checkCancellation()
        throw Failure.invalidImage
      }
      return image
    }

    func begin(_ item: PhotosPickerItem) {
      reset()
      request = Request(item: item)
    }

    /// SwiftUI owns and cancels the task; the request ID also rejects late results.
    func load() async {
      guard let request else { return }
      do {
        let image = try await loadPhoto(request.item)
        guard self.request?.id == request.id else { return }
        self.request = nil
        guard !Task.isCancelled else { return }
        crop = Crop(image: image)
      }
      catch {
        guard self.request?.id == request.id else { return }
        self.request = nil
        guard !Task.isCancelled, !(error is CancellationError) else { return }
        Log.common.error("Could not load avatar: \(error)")
        retryItem = request.item
        showsLoadError = true
      }
    }

    func retry() {
      guard let retryItem else { return }
      begin(retryItem)
    }

    func commit(_ image: UIImage, to participant: Participant) throws {
      guard crop != nil else { throw Failure.noPendingCrop }
      guard let data = encode(image), !data.isEmpty else { throw Failure.encodingFailed }
      // Never assign an optional encoding result: a failure must not erase the avatar.
      participant.avatar = data
    }

    func reset() {
      request = nil
      crop = nil
      retryItem = nil
      showsLoadError = false
    }
  }
#endif
