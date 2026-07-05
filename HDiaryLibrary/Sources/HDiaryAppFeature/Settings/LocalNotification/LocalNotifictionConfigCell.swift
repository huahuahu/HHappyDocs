//
//  LocalNotifictionConfigCell.swift
//  HDiary
//
//  Created by tigerguo on 2023/10/26.
//

import HFoundation
import SwiftUI
import UserNotifications

struct LocalNotifictionConfigCell: View {
  @State private var reminderDate: Date?
  var body: some View {
    NavigationLink(value: HDiaryDestination.settingEntry(.localNotificationSetting)) {
      HStack {
        Label {
          Text(DiaryStringKey.Notification.cellLabel)
        } icon: {
          Image(hDiarySymbol: .bell)
        }
        Spacer()
        currentStatusView
      }
    }
    .task {
      let date = await LocalNotificationManager.shared.getDailyReminderDate()
      await MainActor.run {
        reminderDate = date
      }
    }
  }

  @ViewBuilder
  private var currentStatusView: some View {
    if let reminderDate {
      Text(reminderDate.formatted(date: .omitted, time: .shortened))
    }
    else {
      Text(DiaryStringKey.Notification.notSetLabel)
    }
  }
}

#Preview("cn") {
  NavigationStack {
    Form {
      Section {
        LocalNotifictionConfigCell()
      }
    }
  }
  .environment(\.locale, .cnMainland)
}

#Preview("en") {
  NavigationStack {
    Form {
      Section {
        LocalNotifictionConfigCell()
      }
    }
  }
  .environment(\.locale, .en)
}
