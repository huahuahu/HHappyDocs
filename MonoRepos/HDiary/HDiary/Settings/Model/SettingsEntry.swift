//
//  SettingsEntry.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/4/2.
//

import Foundation
import HUIComponent
import Observation
import SwiftUI

enum SettingEntry: Hashable {
  case localNotificationSetting

  @ViewBuilder
  var targetView: some View {
    switch self {
    case .localNotificationSetting:
      LocalNotificationSettingView()
    }
  }
}
