//
//  AppDelegate.swift
//  HDiary
//
//  Created by tigerguo on 2023/10/27.
//

import Foundation
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
  private var singletons = [Any]()
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    singletons.append(LocalNotificationManager.shared)
    return true
  }
}
