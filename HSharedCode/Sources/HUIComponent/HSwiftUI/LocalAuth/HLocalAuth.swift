//
//  HLocalAuth.swift
//  HUIComponent
//
//  Created by tigerguo on 2023/4/17.
//

import Foundation
import LocalAuthentication

public enum HLocalAuth {
  // 1. If No touch id/face id set(Not enrolled),  deviceOwnerAuthenticationWithBiometrics would return false, error is Error Domain=com.apple.LocalAuthentication Code=-7 "No identities are enrolled."
  // 2. If touch id/ face id is enrolled but denied to use, deviceOwnerAuthenticationWithBiometrics would return false, error is "Error Domain=com.apple.LocalAuthentication Code=-6 "User has denied the use of biometry for this app""
  // 3. If no touchid/faceid/password enrolled, return false. Error is: Optional(Error Domain=com.apple.LocalAuthentication Code=-7 "No identities are enrolled

  public enum AuthPolicyError: Error {
    case notEnabled
    case unKnown
  }

  public static func canAuthWith(policy: LAPolicy) -> Result<Void, AuthPolicyError> {
    let laContext = LAContext()
    var error: NSError?

    if laContext.canEvaluatePolicy(policy, error: &error) {
      return .success(())
    }
    else {
      if let error {
        switch error.code {
        case Int(kLAErrorPasscodeNotSet), Int(kLAErrorBiometryNotEnrolled):
          return .failure(.notEnabled)
        default:
          return .failure(.unKnown)
        }
      }
      else {
        return .failure(.unKnown)
      }
    }
  }
}
