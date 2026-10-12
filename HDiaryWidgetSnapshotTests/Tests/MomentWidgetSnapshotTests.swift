#if DEBUG
  @testable import HDiaryWidgetFeature
  import SnapshotTesting
  import SwiftUI
  import WidgetKit
  import XCTest

  /// Render the production content directly in-process, without SpringBoard or a fixture extension.
  @MainActor
  final class MomentWidgetSnapshotTests: XCTestCase {
    func testMedium() throws {
      try snapshots(family: .systemMedium, height: 164, name: "medium")
    }

    func testLarge() throws {
      try snapshots(family: .systemLarge, height: 365, name: "large")
    }

    func testDateLabels() throws {
      try requireSnapshotEnvironment()
      let now = MomentWidgetPreviewFixtures.date
      let scenarios: [(String, [TimeInterval])] = [
        ("relative-dates", [30.0 * 60, 3 * 3600, 86_400, 2 * 86_400, 6 * 86_400]),
        ("older-dates", [7.0 * 86_400, 370 * 86_400]),
      ]
      for locale in ["zh_CN", "en_US"] {
        for (scenario, ages) in scenarios {
          let moments = ages.enumerated().map { index, age in
            MomentWidgetSummary.Moment(
              timeStamp: now.addingTimeInterval(-age),
              title: locale == "zh_CN" ? "和朋友一起爬山，看到了山顶的日出" : "A lovely walk with friends to watch the sunrise over the hills",
              id: UUID(uuidString: "00000000-0000-0000-0002-00000000000\(index)").unsafelyUnwrapped
            )
          }
          let entry = MomentEntry(date: now, summary: .init(participant: MomentWidgetPreviewFixtures.participant, moments: moments))
          for (family, height, name) in [(WidgetFamily.systemMedium, 164.0, "medium"), (.systemLarge, 365.0, "large")] {
            let view = MomentWidgetContentView(entry: entry, family: family)
              .environment(\.widgetDatesUseLiveTime, false)
              .padding(16)
              .frame(width: 350, height: height)
              .background(.white)
              .environment(\.locale, Locale(identifier: locale))
              .environment(\.calendar, Calendar(identifier: .gregorian))
              .environment(\.timeZone, TimeZone(secondsFromGMT: 8 * 3600).unsafelyUnwrapped)
              .environment(\.colorScheme, .light)
            let traits = UITraitCollection {
              $0.userInterfaceStyle = .light
              $0.displayScale = 3
              $0.preferredContentSizeCategory = .large
            }
            assertSnapshot(
              of: view, as: .image(precision: 1, perceptualPrecision: 1, layout: .fixed(width: 350, height: height), traits: traits),
              named: "\(name)-\(scenario)-\(locale)", record: record, testName: "moment-widget-content"
            )
          }
        }
      }
    }

    func testAccessibility5Rows() throws {
      try requireSnapshotEnvironment()
      let moment = try XCTUnwrap(MomentWidgetPreviewFixtures.longContent.summary.moments.first)
      let traits = UITraitCollection {
        $0.userInterfaceStyle = .light
        $0.displayScale = 3
        $0.preferredContentSizeCategory = .accessibilityExtraExtraExtraLarge
      }
      for (family, name) in [(WidgetFamily.systemMedium, "medium"), (.systemLarge, "large")] {
        // Test the one-line fallback at AX5 without pretending to reproduce WidgetKit's font metrics.
        let row = MomentWidgetRow(
          moment: moment, family: family, referenceDate: MomentWidgetPreviewFixtures.date, titleLineLimit: 1
        )
          .environment(\.widgetDatesUseLiveTime, false)
          .padding(16)
          .frame(width: 350)
          .background(.white)
          .environment(\.locale, Locale(identifier: "zh_CN"))
          .environment(\.calendar, Calendar(identifier: .gregorian))
          .environment(\.timeZone, TimeZone(secondsFromGMT: 8 * 3600).unsafelyUnwrapped)
          .environment(\.dynamicTypeSize, .accessibility5)
          .environment(\.colorScheme, .light)
        assertSnapshot(
          of: row, as: .image(precision: 1, perceptualPrecision: 1, layout: .sizeThatFits, traits: traits),
          named: "\(name)-row-accessibility5", record: record, testName: "moment-widget-content"
        )
      }
    }

    private var record: SnapshotTestingConfiguration.Record {
      ProcessInfo.processInfo.environment["HDIARY_RECORD_WIDGET_SNAPSHOTS"] == "1" ? .all : .never
    }

    private func snapshots(family: WidgetFamily, height: CGFloat, name: String) throws {
      try requireSnapshotEnvironment()
      for snapshot in WidgetSnapshotCase.all {
        XCTContext.runActivity(named: "\(name) · \(snapshot.name)") { _ in
          let accessibility = snapshot.scenario == .accessibility1
          let traits = UITraitCollection {
            $0.userInterfaceStyle = snapshot.appearance.colorScheme == .dark ? .dark : .light
            $0.displayScale = 3
            $0.preferredContentSizeCategory = accessibility ? .accessibilityMedium : .large
          }
          let view = MomentWidgetContentView(entry: snapshot.scenario.entry, family: family)
            .environment(\.widgetDatesUseLiveTime, false)
            // Fixed content canvas; the WidgetKit background, clipping and compositing are not simulated.
            .padding(16)
            .frame(width: 350, height: height)
            .background(Color(uiColor: .systemBackground))
            .environment(\.locale, Locale(identifier: "zh_CN"))
            .environment(\.calendar, Calendar(identifier: .gregorian))
            .environment(\.timeZone, TimeZone(secondsFromGMT: 8 * 3600).unsafelyUnwrapped)
            .environment(\.dynamicTypeSize, accessibility ? .accessibility1 : .large)
            .environment(\.colorScheme, snapshot.appearance.colorScheme)
            .environment(\.widgetRenderingMode, snapshot.appearance.renderingMode)
          assertSnapshot(
            of: view,
            as: .image(precision: 1, perceptualPrecision: 1, layout: .fixed(width: 350, height: height), traits: traits),
            named: "\(name)-\(snapshot.name)", record: record,
            testName: "moment-widget-content"
          )
        }
      }
    }

    private func requireSnapshotEnvironment() throws {
      let model = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"]
      let version = ProcessInfo.processInfo.operatingSystemVersionString
      guard model == "iPhone18,1", version.contains("24A434") else {
        XCTFail("Widget content baselines require iPhone 17 Pro / iOS 27.0 (24A434). Current: \(version)")
        throw ConfigurationError.wrongEnvironment
      }
      // The production views deliberately load these resources from Bundle.main.
      _ = try XCTUnwrap(UIImage(named: "WidgetAppIcon"))
      _ = try XCTUnwrap(UIImage(named: "WidgetAppIconAccented"))
      XCTAssertEqual(String(localized: "moment.empty.label", table: "Intents", bundle: .main), "暂无乐事")
    }

    private enum ConfigurationError: Error {
      case wrongEnvironment
    }
  }
#endif
