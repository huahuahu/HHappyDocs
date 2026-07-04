//
//  SimpleList.swift
//  Libai
//
//  Created by huahuahu on 2021/12/26.
//

import SwiftUI

struct SimpleList: View {
  var body: some View {
    List {
      Text("A List Item")
      Text("A Second List Item")
      Text("A Third List Item")
    }
  }
}

struct TestList_Previews: PreviewProvider {
  static var previews: some View {
    SimpleList()
  }
}
