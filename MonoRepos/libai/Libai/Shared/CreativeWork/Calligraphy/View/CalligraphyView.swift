//
//  CalligraphyView.swift
//  Libai
//
//  Created by huahuahu on 2022/2/5.
//

import SwiftUI

struct CalligraphyView: View {
  @State private var isPresenting = false
  let model: CalligraphyModel
  var body: some View {
    ScrollView(.vertical, showsIndicators: true) {
      VStack(alignment: .leading, spacing: 10) {
        Image(model.imageString)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .onTapGesture {
            isPresenting = true
          }
          .sheet(isPresented: $isPresenting, content: {
            InteractiveImage(imageStr: model.imageString)
          })

        Text(model.summary)
          .font(.body)
          .fixedSize(horizontal: false, vertical: true)
          .padding(.horizontal)

        Text(model.link.markdownToAttributed())
          .padding(.leading)
      }
    }
  }
}

struct CalligraphyView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      CalligraphyView(model: .上阳台帖)
    }
  }
}
