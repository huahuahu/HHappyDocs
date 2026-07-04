//
//  ImagePageView.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/4/17.
//

import HUIComponent
import SwiftUI

struct ImagePageView: View, Identifiable {
  @State private var tappedImage: UIImage?

  enum ContentType {
    case image(_ image: UIImage, id: String)
    case add(_ locatoinID: String)
  }

  let contentType: ContentType
  var background: some View {
    Color.black.opacity(0.2)
  }

  var body: some View {
    switch contentType {
    case let .image(image, _):
      HStack(alignment: .center) {
        Spacer(minLength: 0)

        Image(uiImage: image)
          .resizable()
          .aspectRatio(contentMode: .fit)
        Spacer(minLength: 0)
      }
      .background(background)
      .onTapGesture {
        tappedImage = image
      }

      .sheet(isPresented: .init(get: {
        tappedImage != nil
      }, set: { presented in
        if !presented {
          tappedImage = nil
        }
      })) {
        ZoomableImageView(image: tappedImage!)
      }

    case let .add(locationID):
      GeometryReader { geo in
        HStack {
          Spacer(minLength: 0)
          LocationImagePicker(locationID: locationID)
          Spacer(minLength: 0)
        }
        .frame(height: geo.size.height)
        .background(background)
      }

      .edgesIgnoringSafeArea(.all)
    }
  }

  var id: String {
    switch contentType {
    case let .image(_, id):
      return id
    case .add:
      return "add"
    }
  }
}

struct ImagePageView_Previews: PreviewProvider {
  static var previews: some View {
    ImagePageView(contentType: .add("test"))
  }
}
