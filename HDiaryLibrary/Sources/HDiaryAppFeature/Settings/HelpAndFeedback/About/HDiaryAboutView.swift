//
//  HDiaryAboutView.swift
//  HDiary
//
//  Created by tigerguo on 2024/4/13.
//

#if os(iOS)

import SwiftUI

@MainActor
struct HDiaryAboutView: View {
  var body: some View {
    Form {
      ICPNumberCell()
    }

    .navigationTitle(Text(DiaryStringKey.AppInfo.about))
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview { @MainActor in
  NavigationStack {
    HDiaryAboutView()
//            .navigationBarTitleDisplayMode(.inline)
  }
}

#endif
