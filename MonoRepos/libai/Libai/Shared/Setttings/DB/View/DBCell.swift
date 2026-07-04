//
//  DBCell.swift
//  Libai
//
//  Created by huahuahu on 2022/3/5.
//

import SwiftUI

struct DBCell: View {
  var body: some View {
    NavigationLink("更新cloud data") {
      UploadDataView()
    }
  }
}

struct DBCell_Previews: PreviewProvider {
  static var previews: some View {
    DBCell()
  }
}
