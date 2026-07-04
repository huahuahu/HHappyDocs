//
//  TableLikeLayout.swift
//  Learn
//
//  Created by tigerguo on 2023/9/5.
//

import SwiftUI

struct TableLikeLayout: View {
  var body: some View {
    HStack {
      Grid(alignment: .leading) {
        GridRow {
          Text("\(Date(), style: .relative) ago")
            .monospacedDigit()
            .background(.red)
          Text("longlonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglong")
            .background(.yellow)
        }
        GridRow {
          Text("2")
          Text("short")
            .gridColumnAlignment(.trailing)
        }
      }
      .background(.green)
      Spacer()
    }
  }
}

#Preview {
  TableLikeLayout()
}
