//
//  LocalAuth.swift
//  HDiary
//
//  Created by tigerguo on 2024/1/28.
//

import Foundation
import HDiaryConstants
import HDiaryModel
import HUIComponent
import SwiftUI

@MainActor
extension View {
  func hDiaryLocalAuth(needAuth: Bool) -> some View {
    self
      .localAuth(
        needAuth: .constant(
          needAuth && HLocalAuth.canAuthWith(policy: .deviceOwnerAuthentication).isSuccess
        ),
        localAuthConfig: LocalAuthConfig(
          touchIDReason: String(
            localized: DiaryStringKey.Permission.localAuthReason
          ),
          appName: AppConstants.appName
        )
      )
  }
}
