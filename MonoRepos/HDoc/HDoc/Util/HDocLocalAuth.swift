//
//  HDocLocalAuth.swift
//  HDoc
//
//  Created by tigerguo on 2023/12/30.
//

import Foundation
import HUIComponent
import SwiftUI

@MainActor
extension View {
  func hDocLocalAuth(needAuth: Bool) -> some View {
    self
      .localAuth(
        needAuth: .constant(
          needAuth && HLocalAuth.canAuthWith(policy: .deviceOwnerAuthentication).isSuccess
        ),
        localAuthConfig: LocalAuthConfig(
          touchIDReason: String(
            localized: HDocString.Permission.localAuthReason
          ),
          appName: HDocString.appName
        )
      )
  }
}
