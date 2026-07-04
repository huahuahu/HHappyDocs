//
//  BioChooser.swift
//  Libai
//
//  Created by huahuahu on 2022/2/5.
//

import SwiftUI

@MainActor
struct BioChooser: View {
  @Binding var selectedBioType: BioType

  var body: some View {
    Menu("更多") {
      ForEach(BioType.allCases) { bioType in
        Button(bioType.title) {
          selectedBioType = bioType
        }
      }
    }
  }
}

struct BioChooser_Previews: PreviewProvider {
  @State static var selectedBioType = BioType.annal
  static var previews: some View {
    NavigationView {
      Text(selectedBioType.title)
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            BioChooser(selectedBioType: $selectedBioType)
              .navigationTitle("测试测试测试")
          }
        }
    }
  }
}
