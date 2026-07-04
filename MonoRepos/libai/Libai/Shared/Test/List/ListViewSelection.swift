//
//  ListViewSelection.swift
//  Libai
//
//  Created by huahuahu on 2021/12/26.
//

import SwiftUI

struct ListViewSelection: View {
  struct Ocean: Identifiable, Hashable {
    let name: String
    let id = UUID()
  }

  private var oceans = [
    Ocean(name: "Pacific"),
    Ocean(name: "Atlantic"),
    Ocean(name: "Indian"),
    Ocean(name: "Southern"),
    Ocean(name: "Arctic"),
  ]
  // single selection
//    @State private var multiSelection: UUID?
  @State private var multiSelection = Set<UUID>()

  var body: some View {
    NavigationView {
      VStack {
        List(oceans, selection: $multiSelection) {
          Text($0.name)
        }
        .refreshable {
          hLog("called refresh")
        }
        Text("\(multiSelection.count) selections")
      }
      .navigationTitle("Oceans")
      .toolbar { EditButton() }
    }.navigationBarTitleDisplayMode(.inline)
  }
}

struct ListViewSelection_Previews: PreviewProvider {
  static var previews: some View {
    ListViewSelection()
  }
}
