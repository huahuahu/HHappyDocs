//
//  HDataTypeView.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/3/25.
//

import SwiftUI

/// Show meta data for a given HDataType
struct HDataTypeView: View {
  let hDataType: HDataType
  private func stringView(_ str: String) -> some View {
    VStack {
      HStack {
        Text(LocalizedString.length)
        Spacer()
        Text(str.count.description)
      }
    }
  }

  private func unknownView() -> some View {
    EmptyView()
  }

  #if os(iOS) || os(visionOS)
    private func imageView(_ img: UIImage) -> some View {
      HStack {
        Text(LocalizedString.size)
        Spacer()
        Text(img.size.debugDescription)
      }
    }

  #elseif os(macOS)
    private func imageView(_ img: NSImage) -> some View {
      HStack {
        Text(LocalizedString.size)
        Spacer()
        Text(img.size.debugDescription)
      }
    }
  #endif

  private func dataView(_ data: Data) -> some View {
    HStack {
      Text(LocalizedString.length)
      Spacer()
      Text(data.count.description)
    }
  }

  var body: some View {
    switch hDataType {
    case .data(let data):
      dataView(data)
    case .string(let string, _):
      stringView(string)
    case .image(image: let image):
      imageView(image)
    case .unknown:
      unknownView()
    }
  }
}

struct HDataTypeView_Previews: PreviewProvider {
  static var previews: some View {
    HDataTypeView(hDataType: .string(string: "haha", fileExt: "txt"))
  }
}
