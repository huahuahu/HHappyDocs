//
//  FavPoemButton.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/2/13.
//

import LibaiModel
import SwiftData
import SwiftUI

@MainActor
struct FavPoemButton: View {
  let poemID: Int

  @Query private var favPoems: [FavPoem]
  @Environment(\.modelContext) private var modelContext

  func buttonImageName(like: Bool) -> String {
    like ? SystemImage.like : SystemImage.unlike
  }

  var favPoemIds: [Int] {
    favPoems.compactMap { poem in Int(poem.id) }
  }

  var body: some View {
    AsyncButton {
      if favPoemIds.contains(poemID) {
        if let poemToDelete = favPoems.first(where: { $0.id == poemID }) {
          modelContext.delete(poemToDelete)
        }
      }
      else {
        let favPoem = FavPoem(id: poemID)
        modelContext.insert(favPoem)
      }
    } label: {
      Image(systemName:
        buttonImageName(like: favPoemIds.contains(poemID))
      )
    }
    .disabled(false)
  }
}

struct FavPoemButton_Previews: PreviewProvider {
  static var previews: some View {
    FavPoemButton(poemID: 1)
  }
}
