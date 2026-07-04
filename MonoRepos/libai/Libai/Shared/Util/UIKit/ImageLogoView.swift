//
//  ImageLogoView.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/4/27.
//

import SwiftUI

struct ImageLogoView: View {
  static let logoPadding = 10.0
  let image: UIImage
  var body: some View {
    VStack(spacing: 0) {
      Image(uiImage: image)
      LogoView()
        .padding([.vertical], 10)
    }
    .background()
  }
}

struct ImageLogoView_Previews: PreviewProvider {
  static var previews: some View {
    ImageLogoView(image: UIImage(named: "上阳台帖")!)
  }
}
