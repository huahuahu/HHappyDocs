//
//  RawDataCell.swift
//  HDoc
//
//  Created by tigerguo on 2024/1/5.
//

import HDocModel
import SwiftUI

@MainActor
struct RawDataCell: View {
  var body: some View {
    NavigationLink(value: HDocNavigationTarget.rawData(.list)) {
      Text(verbatim: "raw data")
    }
  }
}

#if DEBUG
  #Preview { @MainActor in
    NavigationStack {
      Form {
        RawDataCell()
      }
      .previewEnvironment()
    }
  }

#endif
