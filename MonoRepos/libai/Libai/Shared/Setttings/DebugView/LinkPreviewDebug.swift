//
//  LinkPreviewDebug.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/5/2.
//

import LinkPresentation
import SwiftUI

struct LinkPreviewDebug: View {
  @State private var meta: LPLinkMetadata?
  var body: some View {
    VStack {
      meta.map { meta in
        LinkView(metaData: meta)
          .frame(height: 300)
      }
    }
    .task {
      let metaDataProvider = LPMetadataProvider()
      let url = URL(string: "https://developer.apple.com/videos/play/wwdc2019/262/")!

      meta = try? await metaDataProvider.startFetchingMetadata(for: url)
      hLog("\(String(describing: meta))", scenerio: .default)
    }
  }
}

struct LinkPreviewDebug_Previews: PreviewProvider {
  static var previews: some View {
    LinkPreviewDebug()
  }
}

struct LinkView: UIViewRepresentable {
  func updateUIView(_: LPLinkView, context _: Context) {}

  let metaData: LPLinkMetadata
  func makeUIView(context _: Context) -> LPLinkView {
    LPLinkView(metadata: metaData)
  }
}
