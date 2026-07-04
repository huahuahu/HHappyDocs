//
//  LoadingView.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/2/13.
//

import SwiftUI

struct LoadingView: View {
  var body: some View {
    ProgressView(PredefinedString.loading)
  }
}

struct LoadingView_Previews: PreviewProvider {
  static var previews: some View {
    LoadingView()
  }
}
