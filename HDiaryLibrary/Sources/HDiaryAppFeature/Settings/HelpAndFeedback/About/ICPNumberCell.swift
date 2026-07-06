//
//  ICPNumberCell.swift
//  HDiary
//
//  Created by tigerguo on 2024/4/13.
//

#if os(iOS)

import SwiftUI

extension HDiaryAboutView {
  @MainActor
  struct ICPNumberCell: View {
    var body: some View {
      NavigationLink(value: HDiaryDestination.icpNumber) {
        Text(DiaryStringKey.AppInfo.icpNumberLabel)
      }
    }
  }
}

struct ICPInfoView: View {
  var body: some View {
    ScrollView {
      Text(DiaryStringKey.AppInfo.icpNumberContent("[苏ICP备2024088589号](https://beian.miit.gov.cn)"))
        .padding()
    }
    .navigationTitle(Text(DiaryStringKey.AppInfo.icpNumberLabel))
    .navigationBarTitleDisplayMode(.inline)
//        .padding()
  }
}

#Preview("icp cell") { @MainActor in
  HDiaryAboutView.ICPNumberCell()
}

#Preview("icp info") { @MainActor in
  NavigationStack {
    ICPInfoView()
  }
  .environment(\.locale, .en)
}

#endif
