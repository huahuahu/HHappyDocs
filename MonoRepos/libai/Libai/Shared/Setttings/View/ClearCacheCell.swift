//
//  ClearCacheCell.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/2/21.
//

import SwiftUI

struct ClearCacheCell: View {
  @State private var shouldShowToast = false
  var body: some View {
    HStack {
      Button {
        UserDefaults.standard.reset()
      } label: {
        Text(PredefinedString.clearCache)
      }
    }
  }
}

struct ClearCacheCell_Previews: PreviewProvider {
  static var previews: some View {
    Form {
      ClearCacheCell()
    }
  }
}
