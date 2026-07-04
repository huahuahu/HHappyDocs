//
//  LocalNotificationPermissionReminderView.swift
//  HDiary
//
//  Created by tigerguo on 2023/10/27.
//

import SwiftUI

/// A view showing user should enable notification permisson
struct LocalNotificationPermissionReminderView: View {
  var body: some View {
    Text(DiaryStringKey.Notification.noPermissionReminder)
  }
}

#Preview {
  LocalNotificationPermissionReminderView()
}
