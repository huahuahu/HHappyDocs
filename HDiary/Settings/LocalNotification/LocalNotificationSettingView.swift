//
//  LocalNotificationSettingView.swift
//  HDiary
//
//  Created by tigerguo on 2023/10/26.
//

import Foundation
import HDiaryConstants
import HDiaryModel
import HFoundation
import SwiftUI

struct LocalNotificationSettingView: View {
  private enum SetReminderStatus: Equatable {
    case notSet
    case fail
    case success
  }

  @State private var selectedDate: Date = Date()
  @State private var notificationAuthStatus: UNAuthorizationStatus?
  @State private var toggleIsOn = false
  @State private var showFailAlert = false
  @State private var setReminderStatus = SetReminderStatus.notSet

  var body: some View {
    Form {
      Section {
        Toggle(isOn: $toggleIsOn, label: {
          Text(DiaryStringKey.Notification.dailyReminderEnableLabel)
        })
        .tint(.accentColor)
      }

      if toggleIsOn {
        Section {
          timePickerView
        } footer: {
          if notificationAuthStatus == .denied {
            LocalNotificationPermissionReminderView()
          }
        }
      }
    }
    .navigationTitle(Text(DiaryStringKey.Notification.cellLabel))
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await updateInitialDate()
      await updateAuthStatus()
    }
    .toolbar {
      toolbarContent
    }
    .alert(isPresented: $showFailAlert, content: {
      Alert(title: Text(DiaryStringKey.Notification.setFailMessage))
    })
    .sensoryFeedback(trigger: setReminderStatus) { oldValue, newValue in
      if oldValue == newValue {
        return nil
      }
      switch newValue {
      case .notSet:
        return nil
      case .fail:
        return .error
      case .success:
        return .success
      }
    }
  }

  @ViewBuilder
  private var timePickerView: some View {
    DatePicker(
      String(localized: DiaryStringKey.Notification.timePickerLabel),
      selection: $selectedDate,
      displayedComponents: .hourAndMinute
    )
    .datePickerStyle(GraphicalDatePickerStyle())
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItem(placement: .primaryAction) {
      Button(action: { Task {
        await MainActor.run {
          setReminderStatus = .notSet
        }
        updateNewDailyReminder()
      }
      }, label: {
        Image(hDiarySymbol: .checkmark)
      })
    }
  }

  private func updateInitialDate() async {
    let date = await LocalNotificationManager.shared.getDailyReminderDate()
    if let date {
      await MainActor.run {
        selectedDate = date
        toggleIsOn = true
      }
    }
    else {
      let calendar = Calendar.current
      var components = DateComponents()
      components.hour = 21
      components.minute = 0
      let defaultDate = calendar.date(from: components)
      await MainActor.run {
        selectedDate = defaultDate ?? Date()
      }
    }
  }

  private func updateNewDailyReminder() {
    guard toggleIsOn else {
      Task {
        await LocalNotificationManager.shared.removeDailyNotification()
        await MainActor.run {
          setReminderStatus = .success
        }
      }
      return
    }

    let calendar = Calendar.current
    let components = calendar.dateComponents([.hour, .minute], from: selectedDate)

    if let hour = components.hour, let minute = components.minute {
      Log.notification.info("save hour \(hour), minute \(minute)")
      Task {
        do {
          let success = try await LocalNotificationManager.shared.scheduleDailyNotification(hour: hour, minute: minute)
          Log.notification.info("set daily reminder finish, result is  \(success)")
          if !success {
            await MainActor.run {
              showFailAlert = true
              setReminderStatus = .fail
            }
          }
          else {
            // should pop
            await MainActor.run {
              setReminderStatus = .success
            }
          }
        }
        catch {
          Log.notification.error("Failed to set daily reminder \(error)")
          await MainActor.run {
            showFailAlert = true
            setReminderStatus = .fail
          }
        }
        await updateAuthStatus()
      }
    }
    else {
      Log.notification.info("Failed to extract hour and minute")
    }
  }

  private func updateAuthStatus() async {
    let authStatus = await LocalNotificationManager.shared.getPermissionStatus()
    await MainActor.run {
      notificationAuthStatus = authStatus
    }
  }
}

#Preview("cn") {
  NavigationStack {
    LocalNotificationSettingView()
  }
  .environment(UserPreferences.shared)
  .environment(\.locale, .cnMainland)
}

#Preview("en") {
  NavigationStack {
    LocalNotificationSettingView()
  }
  .environment(UserPreferences.shared)
  .environment(\.locale, .en)
}
