//
//  ActivityIndicator.swift
//  Libai
//
//  Created by huahuahu on 2021/12/28.
//

import SwiftUI

struct ActivityIndicator: UIViewRepresentable {
  func makeUIView(context _: Context) -> UIActivityIndicatorView {
    UIActivityIndicatorView(style: .medium)
  }

  func updateUIView(_ view: UIActivityIndicatorView, context _: Context) {
    view.startAnimating()
  }
}

struct ContentViewActivityIndicator: View {
  var body: some View {
    ActivityIndicator()
  }
}

struct ActivityIndicator_Previews: PreviewProvider {
  static var previews: some View {
    ContentViewActivityIndicator()
  }
}
