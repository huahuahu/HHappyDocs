//
//  QRCodeGenViewDebug.swift
//  Libai (iOS)
//
//  Created by tigerguo on 2022/4/27.
//

import HUIComponent
import SwiftUI

struct QRCodeGenViewDebug: View {
  let str = "https://apps.apple.com/cn/app/%E6%9D%8E%E7%99%BD/id1609067377?l=en"
  @State private var image: UIImage?
  @State private var presentImage: UIImage?

  @State private var isPresenting = false

  @ViewBuilder
  var content: some View {
    if let image = image {
      HStack {
        Text("来自")

        Image(uiImage: image)
          .renderingMode(.original)
          .resizable()
          .aspectRatio(contentMode: .fit)
//              .border(.red, width: 1)
//              .background(.blue)
      }
      .padding(.horizontal)
      .frame(height: 100)
    }
    else {
      Text("Hello")
    }
  }

  @ViewBuilder
  var testView: some View {
    HStack {
      Text("来自")
        .font(.largeTitle)

      Image(uiImage: image!)
        .renderingMode(.original)
        .resizable()
        .aspectRatio(contentMode: .fit)
    }
    .padding(.horizontal)
    .frame(height: 100)
  }

  var body: some View {
    NavigationView {
      content
        .sheet(isPresented: .init(get: {
          presentImage != nil
        }, set: { isPresenting in
          if !isPresenting {
            presentImage = nil
          }
        }), onDismiss: {}, content: {
          ZoomableImageView(image: presentImage!)
        })
        .toolbar {
          ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button("tap") {
              image = UIImage.generateCode(inputMsg: str, fgImage: nil)
            }

            Button("snapshot") {
              presentImage = testView.snapshot()
              if presentImage != nil {
                isPresenting = true
              }
            }
          }
        }
    }
  }
}

struct QRCodeGenViewDebug_Previews: PreviewProvider {
  static var previews: some View {
    QRCodeGenViewDebug()
  }
}
