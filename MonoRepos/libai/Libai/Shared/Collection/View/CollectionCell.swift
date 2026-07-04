//
//  CollectionCell.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/2/13.
//

import SwiftUI

struct CollectionCell: View {
  let collectionType: CollectionType

  var body: some View {
    HStack {
      Image(systemName: collectionType.systemImageName)
        .foregroundColor(Color.accentColor)
        .symbolRenderingMode(.monochrome)
//        .symbolRenderingMode(.multicolor)
      Text(collectionType.title)
    }
  }
}

struct CollectionCell_Previews: PreviewProvider {
  static var previews: some View {
    CollectionCell(collectionType: .fav)
  }
}
