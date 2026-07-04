//
//  ErrorView.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/2/13.
//

import SwiftUI

struct ErrorView: View {
  init(onRetry: (() async -> Void)? = nil) {
    self.onRetry = onRetry
  }

  let onRetry: (() async -> Void)?
  var body: some View {
    Text(PredefinedString.loadFail)
      .onTapGesture {
        Task {
          await onRetry?()
        }
      }
  }
}

struct ErrorView_Previews: PreviewProvider {
  static var previews: some View {
    ErrorView()
  }
}
