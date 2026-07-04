//
//  ClipboardNavigator.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/3/18.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct ClipboardNavigatorModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .navigationDestination(for: InspectEntry.self) { entry in
        InspectorWrapperView(entry: entry)
        #if os(iOS) || os(visionOS)
          .navigationBarTitleDisplayMode(.inline)
        #endif
          .navigationTitle(entry.text)
      }
      .navigationDestination(for: HPasteboardItemRepresentation.self) { representation in
        HPasteboardRepresentationView(representation: representation)
      }
      .navigationDestination(for: UTType.self) { uttype in
        HUTView(utType: uttype)
      }
      .navigationDestination(for: HDescription.self) { hDescription in
        HDescriptionView(hDescription: hDescription)
      }
      .navigationDestination(for: InteractionItem.self) { item in
        InteractionWrapperView(item: item)
      }
  }
}

extension View {
  func clipboardNavigator() -> some View {
    modifier(ClipboardNavigatorModifier())
  }
}
