//
//  NavigationModifier.swift
//  Libai (iOS)
//
//  Created by tigerguo on 2022/9/7.
//

import Foundation
import SwiftUI

struct HNavigationViewModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .navigationDestination(for: AnnalToDisplay.self) { annal in
        AnnalDetailView(annalToDisplay: annal)
      }
      .navigationDestination(for: Location.self) { location in
        LocationView(location: location)
      }
      .navigationDestination(for: Poem.self) { poem in
        PoemDetailView(poemID: poem.id)
      }
      .navigationDestination(for: PoemKey.self, destination: { poemKey in
        PoemDetailView(poemID: poemKey.poemID)
      })
      .navigationDestination(for: SearchedPoem.self) { poem in
        PoemDetailView(poemID: poem.poemID)
      }
      .navigationDestination(for: TagKey.self) { tagKey in
        TagPoemsListView(tag: tagKey.tag)
      }
  }
}

extension View {
  func hNavigationDestination() -> some View {
    modifier(HNavigationViewModifier())
  }
}
