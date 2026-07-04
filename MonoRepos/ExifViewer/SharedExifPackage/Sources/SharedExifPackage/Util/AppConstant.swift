//
//  AppConstant.swift
//  SharedExifPackage
//
//  Created by tigerguo on 2025/3/7.
//

#if os(iOS)

  import Foundation
  import UIKit

  public enum AppConstant {
    // Get app name
    static let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Exif"

    static let proAppTintColor = UIColor.systemPurple

    // URLs
    public static let copiedImageFolder = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("CopiedImages", isDirectory: true)
  }

#endif
