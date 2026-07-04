//
//  CalligraphyList.swift
//  Libai
//
//  Created by huahuahu on 2022/2/5.
//

import SwiftUI

struct CalligraphyList: View {
  var body: some View {
    List([CalligraphyModel.上阳台帖]) { model in
      NavigationLink {
        CalligraphyView(model: model)
      } label: {
        Text(model.title)
      }
    }
  }
}

struct CalligraphyList_Previews: PreviewProvider {
  static var previews: some View {
    CalligraphyList()
  }
}
