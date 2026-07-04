//
//  PoemContentView.swift
//  Libai
//
//  Created by huahuahu on 2022/2/6.
//

import SwiftUI

struct PoemContentView: View {
  var content: AttributedString
  @Binding var annotate: String?
  var body: some View {
    VStack(alignment: .leading) {
      Text(PredefinedString.rawText)
        .font(.subheadline)
        .bold()
        .padding()
      HStack {
        Spacer()
        Text(content)
          .font(.body)
          .padding(.horizontal)
          .environment(\.openURL, OpenURLAction(handler: { url in
            if let pattern = URLHandler.Pattern(url: url),
               pattern.host == .annotate {
              annotate = pattern.value
              return .handled
            }
            return .systemAction
          }))
        Spacer()
      }
    }
  }
}

struct PoemContentView_Previews: PreviewProvider {
  static var previews: some View {
    PoemContentView(content: "床前明月光", annotate: .constant("annotate"))
  }
}
