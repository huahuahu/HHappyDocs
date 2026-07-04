//
//  MediaLearnList.swift
//  Learn
//
//  Created by tigerguo on 2023/11/12.
//

import SwiftUI

struct MediaLearnList: View {
  var body: some View {
    List(MediaLearnEntry.allCases) { entry in
      NavigationLink(value: NavigationTarget.mediaLearn(item: entry)) {
        VStack {
          Text(entry.title)
        }
      }
    }
    .navigationTitle("Media")
  }
}

#Preview {
  MediaLearnList()
}
