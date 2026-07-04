//
//  UpdateDBCell.swift
//  Libai
//
//  Created by huahuahu on 2022/3/5.
//

import SwiftUI

struct UpdateDBCell: View {
  let dbAction: DBAaction
  var body: some View {
    Button {
      DBUploader(action: dbAction).perform()
    } label: {
      Text(dbAction.titleInCell)
    }
  }
}

struct UpdateDBCell_Previews: PreviewProvider {
  static var previews: some View {
    UpdateDBCell(dbAction: .check)
  }
}
