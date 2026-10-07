#if os(iOS)
  import Foundation
  import HDiaryConstants
  import Observation

  /// Owns one avatar's preparation and SwiftUI Quick Look presentation.
  @Observable
  final class ParticipantAvatarPreview {
    struct Source: Equatable {
      let participantID: UUID
      let data: Data?
      let isEnabled: Bool
    }

    struct Request {
      let id = UUID()
      let data: Data
    }

    var previewURL: URL?
    var showsError = false
    private(set) var request: Request?
    private let prepareFile: @MainActor (Data) async throws -> URL

    init(prepareFile: @escaping @MainActor (Data) async throws -> URL = ParticipantAvatarPreview.prepareOriginalFile) {
      self.prepareFile = prepareFile
    }

    private static func prepareOriginalFile(_ data: Data) async throws -> URL {
      try await ParticipantAvatarPreviewFiles.shared.prepare(data)
    }

    func begin(data: Data) {
      guard request == nil, previewURL == nil else { return }
      showsError = false
      request = Request(data: data)
    }

    /// Called by a view-scoped task, so disappearing views cancel preparation.
    func prepare() async {
      guard let request else { return }
      do {
        let url = try await prepareFile(request.data)
        guard self.request?.id == request.id else { return }
        self.request = nil
        guard !Task.isCancelled else { return }
        previewURL = url
      }
      catch {
        guard self.request?.id == request.id else { return }
        self.request = nil
        guard !Task.isCancelled, !(error is CancellationError) else { return }
        Log.common.error("Could not prepare avatar preview: \(error)")
        showsError = true
      }
    }

    func reset() {
      request = nil
      previewURL = nil
      showsError = false
    }
  }
#endif
