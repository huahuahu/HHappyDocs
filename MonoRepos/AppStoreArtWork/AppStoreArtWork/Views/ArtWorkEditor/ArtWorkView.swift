//
//  ArtWorkView.swift
//  AppStoreArtWork
//
//  Created by tigerguo on 2025/3/19.
//

import SwiftUI

struct ArtWorkView: View {
  let target: Target
  let scale: Double
  let bezelScale = 0.85

  let model: ArtWorkModel
  init(target: Target, scale: Double, model: ArtWorkModel) {
    self.target = target
    self.scale = scale

    self.model = model
  }

  var body: some View {
    ZStack {
      Color.red
      VStack(spacing: 10 * scale) {
        Text(model.title.isEmpty ? "标题" : model.title)
          .font(.system(size: 72 * scale))
          .foregroundColor(.white)
          .frame(maxWidth: .infinity, alignment: .top)
//          .border(.blue, width: 1)

        Text(model.subtitle.isEmpty ? "副标题" : model.subtitle)
          .font(.system(size: 54 * scale))
          .foregroundColor(.white)
          .frame(maxWidth: .infinity, alignment: .top)
          .padding(.top, 54 * scale)
//          .border(.blue, width: 1)

        imageSection
          .frame(width: target.bezelSize.width * scale * bezelScale, height: target.bezelSize.height * scale * bezelScale)
      }
      .frame(maxWidth: .infinity, alignment: .top)
//      .border(.green, width: 1)
    }
  }

  var imageSection: some View {
    ZStack {
      ImageAddView(model: model)
        .clipShape(RoundedRectangle(cornerSize: CGSize(width: target.cornerSize.width * scale * bezelScale, height: target.cornerSize.height * scale * bezelScale), style: .continuous))
        .frame(width: target.size.width * scale * bezelScale, height: target.size.height * scale * bezelScale)
      Image(target.bezel)
        .resizable()
    }
  }
}

#Preview {
  let scale = 0.5
  NavigationStack {
    ScrollView([.horizontal, .vertical]) {
      ArtWorkView(target: .sixFiveInch, scale: scale, model: .getEmptyModel())
        .frame(width: Target.sixFiveInch.size.width * scale, height: Target.sixFiveInch.size.height * scale)
    }
  }
  .frame(width: Target.sixFiveInch.size.width * scale, height: Target.sixFiveInch.size.height * scale)
}
