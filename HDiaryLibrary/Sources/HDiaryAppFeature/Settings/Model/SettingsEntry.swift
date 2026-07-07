//
//  SettingsEntry.swift
//  HDiary
//
//  Created by tigerguo on 2023/4/2.
//

#if os(iOS)

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

#endif
