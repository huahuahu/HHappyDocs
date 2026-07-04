//
//  AttrStringDemo.swift
//  Libai
//
//  Created by huahuahu on 2021/12/29.
//

import SwiftUI
import UIKit

struct HTMLView: UIViewRepresentable {
  func updateUIView(_: UITextView, context _: Context) {}

  let attributeString: NSAttributedString
  init(_ data: Data) {
    do {
      let attr = try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
      attributeString = attr
    }
    catch {
      attributeString = NSAttributedString(string: "error: \(error)")
    }
  }

  func makeUIView(context _: Context) -> UITextView {
    let textView = UITextView()
    textView.attributedText = attributeString
    textView.isEditable = false
    textView.isSelectable = false
    return textView
  }
}

struct AttrStringDemo: View {
  @State var htmlData: Data?
  @State var state = "loading"

  func requestData() async {
    guard let url = URL(string: "http://localhost:9000/libai/api/annal/1") else {
      state = "url error"
      return
    }

    do {
      let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
      htmlData = data
      state = "load finish"
    }
    catch {
      state = "fetch \(error)"
    }
  }

  @ViewBuilder
  var contentView: some View {
    if let data = htmlData {
      HTMLView(data).padding(20)
    }
    else {
      Text(state)
    }
  }

  var body: some View {
    contentView.onAppear {
      Task {
        await requestData()
      }
    }
  }
}

struct AttrStringDemo_Previews: PreviewProvider {
  static var previews: some View {
    AttrStringDemo()
  }
}
