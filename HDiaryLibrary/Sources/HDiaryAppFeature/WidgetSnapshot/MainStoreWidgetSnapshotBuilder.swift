#if os(iOS)

  import HDiaryWidgetData
  import SwiftData

  @MainActor
  struct MainStoreWidgetSnapshotBuilder: WidgetSnapshotBuilding {
    private let sourceReader: MainStoreWidgetSnapshotSourceReader

    init(container: ModelContainer) {
      sourceReader = MainStoreWidgetSnapshotSourceReader(container: container)
    }

    func build() async throws -> WidgetSnapshotValue {
      let source = try await sourceReader.read()

      return await WidgetSnapshotProjector.project(
        participants: source.participants,
        moments: source.moments,
        limit: 8,
        thumbnail: {
          await WidgetAvatarThumbnailer.thumbnailData(from: $0, maxPixelSize: 64)
        }
      )
    }
  }

#endif
