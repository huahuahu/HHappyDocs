//
//  LogoView.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/4/27.
//

import SwiftUI

struct LogoView: View {
  static let height = 30.0
  var body: some View {
    HStack {
      Spacer()
      Text(PredefinedString.powerdBy)
      Image("Logo")
        .resizable()
        .aspectRatio(contentMode: .fit)
      Spacer()
      #if os(iOS)
        Image(uiImage: UIImage.appQRCodeImage)
          .resizable()
          .aspectRatio(contentMode: .fit)
      #endif
    }
    .padding([.horizontal])
    .frame(height: Self.height)
  }
}

struct LogoView_Previews: PreviewProvider {
  static var previews: some View {
    LogoView()
  }
}
