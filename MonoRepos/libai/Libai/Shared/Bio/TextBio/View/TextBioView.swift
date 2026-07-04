//
//  TextBioView.swift
//  Libai
//
//  Created by huahuahu on 2022/2/5.
//

import SwiftUI

struct TextBioView: View {
  let bioModel: BioModel
  var body: some View {
    ScrollView(.vertical) {
      Text(bioModel.rawText)
        .font(.body)
        .padding()
    }
  }
}

struct TextBioView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      TextBioView(bioModel: .demo)
        .navigationTitle("才子传")
    }
  }
}

extension BioModel {
  static let demo = BioModel(rawText: String(dataSetName: "唐才子传"))
}
