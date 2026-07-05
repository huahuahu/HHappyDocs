//
//  LocalNotificationManager.swift
//  HDiary
//
//  Created by tigerguo on 2023/10/26.
//

import Foundation
import HDiaryConstants
import HDiaryModel
import HDiaryServices
import UIKit
import UserNotifications

actor LocalNotificationManager: NSObject {
  static let shared = LocalNotificationManager()
  private let localNotificationCenter: UNUserNotificationCenter = UNUserNotificationCenter.current()
  override private init() {
    super.init()

    localNotificationCenter.delegate = self
  }
}

// MARK: delegate

extension LocalNotificationManager: UNUserNotificationCenterDelegate {
  @MainActor
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
    //        let userInfo = response.notification.request.content.userInfo

    guard let identifier = Identider(rawValue: response.notification.request.identifier) else {
      Log.notification.error("Can't find logic for \(response.notification.request.identifier)")
      return
    }
    switch identifier {
    case .dailyReminer:
      Log.notification.info("did recive daily reminder")
      if let url = DeepLink.getAddMomentUrl() {
        Task { @MainActor in
          let result = await UIApplication.shared.open(url)
          Log.notification.info("open add moment url \(result)")
        }
      }
    }
  }

  @MainActor
  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
    return [.badge, .banner, .sound]
  }
}

// MARK: Daily Reminder

extension LocalNotificationManager {
  func scheduleDailyNotification(hour: Int, minute: Int) async throws -> Bool {
    let granted = try await localNotificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
    if !granted {
      Log.notification.info("failed to get notification permission")
      return false
    }

    removeDailyNotification()

    let content = UNMutableNotificationContent()
    content.title = String(localized: DiaryStringKey.Notification.reminderContentTitle)
    content.body = String(localized: DiaryStringKey.Notification.reminderContentBody)

    // 设置通知触发器，每天的固定时间触发
    var dateComponents = DateComponents()
    dateComponents.hour = hour
    dateComponents.minute = minute
    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
//    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

    // 创建通知请求
    let request = UNNotificationRequest(identifier: Identider.dailyReminer.rawValue, content: content, trigger: trigger)

    // 将通知请求添加到通知中心
    Log.notification.info("try set new daily reminder")
    try await localNotificationCenter.add(request)
    Log.notification.info("set new daily reminder success")
    return true
  }

  func getDailyReminderDate() async -> Date? {
    let requests = await localNotificationCenter.pendingNotificationRequests()
    let dailyReminderRequest = requests.first { $0.identifier == Identider.dailyReminer.rawValue }
    guard let trigger = dailyReminderRequest?.trigger as? UNCalendarNotificationTrigger else {
      return nil
    }
    return trigger.nextTriggerDate()
  }

  func getPermissionStatus() async -> UNAuthorizationStatus {
    return await localNotificationCenter.notificationSettings().authorizationStatus
  }

  func removeDailyNotification() {
    localNotificationCenter.removePendingNotificationRequests(withIdentifiers: [Identider.dailyReminer.rawValue])
    Log.notification.info("remove previous daily reminder")
  }
}

extension LocalNotificationManager {
  enum Identider: String {
    case dailyReminer
  }
}
