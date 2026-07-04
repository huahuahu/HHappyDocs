//
//  InteractiveImage.swift
//  Libai
//
//  Created by huahuahu on 2022/2/5.
//

import HUIComponent
import SwiftUI

struct InteractiveImage: View {
  @Environment(\.presentationMode) var presentationMode

  let imageStr: String
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        Spacer()
        ZoomableImageView(image: UIImage(named: imageStr).unsafelyUnwrapped)
        Spacer()
      }
      .frame(width: geometry.size.width, height: geometry.size.height)
      .overlay(alignment: .topTrailing) {
        Button {
          presentationMode.wrappedValue.dismiss()
        } label: {
          Text(PredefinedString.close)
        }
        .padding()
      }
    }
  }
}

struct InteractiveImage_Previews: PreviewProvider {
  static var previews: some View {
    InteractiveImage(imageStr: "上阳台帖")
  }
}
