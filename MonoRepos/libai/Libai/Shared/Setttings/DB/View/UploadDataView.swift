//
//  UploadDataView.swift
//  Libai
//
//  Created by huahuahu on 2022/3/5.
//

import CoreData
import SwiftUI

struct UploadDataView: View {
  var body: some View {
    List(DBAaction.allCases) { action in
      UpdateDBCell(dbAction: action)
    }
  }
}

struct UploadDataView_Previews: PreviewProvider {
  static var previews: some View {
    UploadDataView()
  }
}
