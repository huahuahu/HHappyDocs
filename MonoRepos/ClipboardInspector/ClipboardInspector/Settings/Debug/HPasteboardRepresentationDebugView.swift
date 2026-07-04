//
//  HPasteboardRepresentationDebugView.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/3/21.
//

#if DEBUG

  import Foundation
  import SwiftUI

  struct HPasteboardRepresentationDebugView: View {
    private let array: [HPasteboardItemRepresentation] = [.plainText, .utf16text]
    var body: some View {
      ForEach(array) { representation in
        NavigationLink(value: representation) {
          Text(representation.type)
        }
      }
    }
  }
#endif
