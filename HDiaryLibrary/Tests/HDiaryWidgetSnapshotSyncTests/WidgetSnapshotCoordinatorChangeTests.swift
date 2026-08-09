#if os(iOS)

  @testable import HDiaryWidgetSnapshotSync
  import HDiaryWidgetData
  import Testing

  @MainActor
  struct WidgetSnapshotCoordinatorChangeTests {
    @Test("writer 报告 no-op 时不刷新 timeline")
    func unchangedSnapshotDoesNotReloadTimeline() async {
      let reloader = ReloaderSpy()
      let coordinator = WidgetSnapshotCoordinator(
        builder: BuilderStub(),
        writer: WriterStub(didChange: false),
        sleep: {},
        reloadTimeline: reloader.reload
      )

      await coordinator.rebuildNow()

      #expect(reloader.reloadCount == 0)
    }
  }

  private nonisolated struct BuilderStub: WidgetSnapshotBuilding {
    func build() -> WidgetSnapshotValue {
      WidgetSnapshotValue(participants: [], moments: [])
    }
  }

  private actor WriterStub: WidgetSnapshotWriting {
    let didChange: Bool

    init(didChange: Bool) {
      self.didChange = didChange
    }

    func replace(with _: WidgetSnapshotValue) -> Bool {
      didChange
    }
  }

  @MainActor
  private final class ReloaderSpy {
    private(set) var reloadCount = 0

    func reload() {
      reloadCount += 1
    }
  }

#endif
