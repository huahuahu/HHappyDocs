#if os(iOS)
  import Observation
  import UIKit

  @Observable
  final class ParticipantAvatarLoader {
    struct Request: Equatable {
      let participantID: UUID
      let data: Data?
      let maxPixelSize: Int
    }

    enum Presentation {
      case loading
      case placeholder
      case image(UIImage, data: Data)
    }

    private struct LoadedAvatar {
      let request: Request
      let entry: ParticipantAvatarImageStore.Entry
    }

    private let store: ParticipantAvatarImageStore
    private var loaded: LoadedAvatar?
    @ObservationIgnored private var activeLoadID: UUID?

    init(store: ParticipantAvatarImageStore = .shared) {
      self.store = store
    }

    func presentation(for request: Request) -> Presentation {
      // Read view-local state even on a cache hit, so load completion stays observed.
      let loaded = loaded
      guard let data = request.data else { return .placeholder }
      if let cached = store.cachedImage(for: data, maxPixelSize: request.maxPixelSize) {
        return cached.image.map { .image($0, data: data) } ?? .placeholder
      }
      if let loaded, loaded.request.participantID == request.participantID {
        if let image = loaded.entry.image, let previousData = loaded.request.data {
          // Keep the visible photo while a replacement or larger rendition is loading.
          return .image(image, data: previousData)
        }
        if loaded.request.data == data {
          return .placeholder
        }
      }
      return .loading
    }

    func load(_ request: Request) async {
      let loadID = UUID()
      activeLoadID = loadID
      guard let data = request.data else {
        loaded = nil
        return
      }
      if let loaded, loaded.request == request {
        return
      }
      guard let entry = try? await store.image(for: data, maxPixelSize: request.maxPixelSize),
            !Task.isCancelled, activeLoadID == loadID
      else { return }
      loaded = LoadedAvatar(request: request, entry: entry)
    }
  }
#endif
