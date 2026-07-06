//
//  AppDelegate.swift
//  HDiary
//
//  Created by tigerguo on 2023/10/27.
//

#if os(iOS)

import Foundation
import UIKit

public final class AppDelegate: NSObject, UIApplicationDelegate {
  private var singletons = [Any]()

  public override init() {
    super.init()
  }

  public func application(_ application: UIApplication,
                          didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    singletons.append(LocalNotificationManager.shared)
    return true
  }
}

#endif
