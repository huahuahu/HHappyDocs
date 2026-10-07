#if DEBUG && os(iOS)
  @testable import HDiarySnapshotHost
  import SnapshotTesting
  import SwiftUI

  @MainActor
  enum ListSnapshotConfiguration {
    static var record: SnapshotTestingConfiguration.Record {
      ProcessInfo.processInfo.environment["HDIARY_RECORD_SNAPSHOTS"] == "1" ? .all : .never
    }

    static func name(_ scenario: String) throws -> String {
      "\(scenario)-\(try Device.current().rawValue)"
    }

    static func image<V: View>(
      style: UIUserInterfaceStyle = .light,
      contentSize: UIContentSizeCategory = .large,
      width: CGFloat? = nil
    ) throws -> Snapshotting<V, UIImage> {
      let device = try Device.current()
      guard let window = SnapshotHostWindow.window, let scene = window.windowScene else {
        throw ConfigurationError("截图宿主的窗口尚未就绪。")
      }
      let bounds = scene.effectiveGeometry.coordinateSpace.bounds
      guard bounds.size == device.portraitSize else {
        throw ConfigurationError("\(device.rawValue) 需要竖屏 \(device.portraitSize)，当前为 \(bounds.size)；Duo 请使用 Closed 形态。")
      }
      // Restore the key window after the narrow-width scenario before reading its safe area.
      window.frame = bounds
      window.layoutIfNeeded()
      let traits = UITraitCollection {
        $0.userInterfaceStyle = style
        $0.displayScale = window.traitCollection.displayScale
        $0.preferredContentSizeCategory = contentSize
      }
      let config = ViewImageConfig(
        safeArea: window.safeAreaInsets,
        size: CGSize(width: width ?? bounds.width, height: bounds.height), traits: traits
      )
      // System glass shadows vary by 1–2 RGB levels across local and CI renders.
      // Check every pixel; tolerate only the previously measured perceptual noise.
      var strategy = Snapshotting<V, UIImage>.image(
        drawHierarchyInKeyWindow: true, precision: 1, perceptualPrecision: 0.94,
        layout: .device(config: config), traits: traits
      )
      // Compare the same PNG representation that is stored in the baseline. The live
      // glass render can use extended-range colors that differ from its PNG encoding.
      let snapshot = strategy.snapshot
      let diffing = strategy.diffing
      strategy.snapshot = { view in
        snapshot(view).map { diffing.fromData(diffing.toData($0)) }
      }
      return strategy
    }

    private enum Device: String {
      case iPhone = "iphone"
      case duo = "iphone-duo"

      var portraitSize: CGSize {
        switch self {
        case .iPhone: CGSize(width: 402, height: 874)
        case .duo: CGSize(width: 466, height: 678)
        }
      }

      static func current() throws -> Device {
        let model = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "unknown"
        let device: Device
        switch model {
        case "iPhone18,1": device = .iPhone
        case "iPhone19,4": device = .duo
        default: throw ConfigurationError("截图测试需要 iPhone 17 Pro 或 iPhone Duo，当前型号为 \(model)。")
        }
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let minorVersion = device == .duo ? 1 : 0
        guard version.majorVersion == 27, version.minorVersion == minorVersion else {
          throw ConfigurationError("\(device.rawValue) 基准需要 iOS 27.\(minorVersion)，请切换测试运行目标。")
        }
        return device
      }
    }

    private struct ConfigurationError: Error, CustomStringConvertible {
      let description: String

      init(_ description: String) {
        self.description = description
      }
    }
  }
#endif
