//
//  AppDelegate.swift
//  ExifViewer
//
//  Created by tigerguo on 2025/3/8.
//

import Foundation
import SharedExifPackage
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
  private var singletons = [Any]()
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    Log.common.info("ExifViewerApp didFinishLaunching")
    clearCache()
    return true
  }

  private func clearCache() {
    Task {
      do {
        try FileManager.default.removeItem(at: AppConstant.copiedImageFolder)
        Log.common.info("Remove copied image cache succeeded")
      }
      catch {
        Log.common.error("Failed to remove copied image cache with error: \(error, privacy: .public)")
      }
    }
  }
}
