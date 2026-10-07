#if os(iOS)
  import Foundation
  import HDiaryConstants
  import ImageIO
  import UniformTypeIdentifiers

  /// Serializes file I/O away from the main actor; never re-encodes the original image.
  actor ParticipantAvatarPreviewFiles {
    static let shared = ParticipantAvatarPreviewFiles()

    enum PreparationError: Error, Equatable {
      case unsupportedImage
    }

    private let root: URL
    private let sessionDirectory: URL
    private var isDirectoryReady = false

    init(root: URL = FileManager.default.temporaryDirectory.appendingPathComponent("ParticipantAvatarPreviews")) {
      self.root = root
      sessionDirectory = root.appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    func prepare(_ data: Data) throws -> URL {
      try Task.checkCancellation()
      guard let source = CGImageSourceCreateWithData(data as CFData, nil),
            CGImageSourceGetCount(source) > 0,
            let identifier = CGImageSourceGetType(source),
            let type = UTType(identifier as String), type.conforms(to: .image),
            let fileExtension = type.preferredFilenameExtension
      else { throw PreparationError.unsupportedImage }

      try prepareDirectory()
      let directory = sessionDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
      let url = directory.appendingPathComponent("image").appendingPathExtension(fileExtension)
      do {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
        try Task.checkCancellation()
        return url
      }
      catch {
        if FileManager.default.fileExists(atPath: directory.path) {
          removeFile(at: directory)
        }
        throw error
      }
    }

    private func prepareDirectory() throws {
      let manager = FileManager.default
      // quickLookPreview has no dismissal/share-completion callback. Retain this
      // process's files, including after dismissal or source changes, for Quick Look
      // and share extensions. Only a later process's first preview prunes them.
      if !isDirectoryReady {
        try manager.createDirectory(at: root, withIntermediateDirectories: true)
        for directory in try manager.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
          where directory != sessionDirectory && UUID(uuidString: directory.lastPathComponent) != nil {
          removeFile(at: directory)
        }
      }
      // The OS may reclaim temporary storage while the app is inactive.
      // Recreate our directory on retry without pruning this session's other files.
      try manager.createDirectory(at: sessionDirectory, withIntermediateDirectories: true)
      isDirectoryReady = true
    }

    private func removeFile(at url: URL) {
      do {
        try FileManager.default.removeItem(at: url)
      }
      catch {
        Log.common.error("Could not remove an avatar preview file: \(error)")
      }
    }
  }
#endif
