//
//  ActivityViewController.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/4/25.
//

import SwiftUI
import UIKit

struct ActivityViewController: UIViewControllerRepresentable {
  var activityItems: [Any]
  var applicationActivities: [UIActivity]?
  var onFinish: (UIActivity.ActivityType?, Bool) -> Void

  func makeUIViewController(context _: UIViewControllerRepresentableContext<Self>) -> UIActivityViewController {
    let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    controller.completionWithItemsHandler = { type, success, _, error in
      hLog("ActivityViewController finish \(String(describing: type)), \(success), error \(String(describing: error))", scenerio: .default)
      onFinish(type, success)
    }
    return controller
  }

  func updateUIViewController(_: UIActivityViewController, context _: UIViewControllerRepresentableContext<Self>) {}
}
