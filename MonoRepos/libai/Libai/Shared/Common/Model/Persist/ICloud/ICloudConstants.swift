//
//  ICloudConstants.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/3/8.
//

import CloudKit
import Foundation
import LibaiAppConstants

// https://stackoverflow.com/a/40414108/2739854
// com.apple.developer.icloud-container-environment to true to use prod icloud
// Only work on device

enum ICloudConstants {
  /// The CloudKit container we'll use.
  static let container = CKContainer(identifier: AppConstants.cloudKitContainerIdentifier)
  /// For this sample we use the iCloud user's private database.
  static let publicDatabase = container.publicCloudDatabase

  static let feedBackRecordName = "feedback"

  static var userID: String = ""
}
