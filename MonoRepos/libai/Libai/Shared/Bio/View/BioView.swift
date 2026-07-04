//
//  BioView.swift
//  Libai
//
//  Created by huahuahu on 2021/12/25.
//

import SwiftUI

@MainActor
struct BioView: View {
  @State var selectedBioType = BioType.annal

  @EnvironmentObject var navigationModel: HNavigationModel

  @ViewBuilder
  var content: some View {
    switch selectedBioType.displayType {
    case .text:
      TextBioView(bioModel: selectedBioType.bioModel.unsafelyUnwrapped)
    case .annalList:
      AnnalView()
    }
  }

  var body: some View {
    NavigationStack(path: $navigationModel.bioPath) {
      content
        .navigationTitle(selectedBioType.title)
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            BioChooser(selectedBioType: $selectedBioType)
          }
        }
        .hNavigationDestination()
    }
  }
}

struct BioView_Previews: PreviewProvider {
  static var previews: some View {
    BioView()
      .environmentObject(HNavigationModel())
  }
}
