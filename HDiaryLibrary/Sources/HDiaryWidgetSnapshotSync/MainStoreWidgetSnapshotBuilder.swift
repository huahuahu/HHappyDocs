#if os(iOS)

  import HDiaryConstants
  import HDiaryWidgetData
  import SwiftData

  /// 串联主 Store 读取与快照投影，并将计算工作移出调用方 actor。
  nonisolated struct MainStoreWidgetSnapshotBuilder: WidgetSnapshotBuilding {
    private let sourceReader: MainStoreWidgetSnapshotSourceReader

    init(container: ModelContainer) {
      sourceReader = MainStoreWidgetSnapshotSourceReader(container: container)
    }

    @concurrent
    func build() async throws -> WidgetSnapshotValue {
      let limit = 8
      let source = try await sourceReader.read(limit: limit)
      Log.Widget.snapshot.log(
        level: DiagnosticLogging.level(for: .debug),
        "Read widget snapshot source: participants=\(source.participants.count, privacy: .public), moments=\(source.moments.count, privacy: .public)"
      )

      return await WidgetSnapshotProjector.project(
        participants: source.participants,
        moments: source.moments,
        limit: limit,
        thumbnail: {
          await WidgetAvatarThumbnailer.thumbnailData(from: $0, maxPixelSize: 64)
        }
      )
    }
  }

#endif
