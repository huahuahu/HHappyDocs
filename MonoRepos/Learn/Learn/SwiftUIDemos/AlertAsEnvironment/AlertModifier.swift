//
//  AlertModifier.swift
//  Learn
//
//  Created by tigerguo on 2025/3/23.
//

import SwiftUI

public struct AlertModifier: ViewModifier {
  @State private var showAlert = false
  @State private var alertTitle = ""
  @State private var alertMessage = ""

  public func body(content: Content) -> some View {
    content
      .alert(isPresented: $showAlert) {
        Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
      }
      .environment(\.showAlert, { title, message in
        Log.common.info("showing Alert: \(title) \(message)")
        alertTitle = title
        alertMessage = message
        showAlert = true
      })
  }
}

public extension View {
  func withAlert() -> some View {
    self.modifier(AlertModifier())
  }
}

public extension EnvironmentValues {
  @Entry var showAlert: (_ title: String, _ message: String) -> Void = {
    print("default Alert: \($0) \($1)")
  }
}
