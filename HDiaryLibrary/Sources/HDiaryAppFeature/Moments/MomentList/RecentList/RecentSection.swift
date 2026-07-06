//
//  RecentSection.swift
//  HDiary
//
//  Created by tigerguo on 2025/5/4.
//

import HDiaryModel
import SFSafeSymbols
import SwiftUI

extension MomentListScreen {
  @MainActor
  struct RecentSection: View {
    let moreMomentCount: Int
    var body: some View {
      Section {
        NavigationLink(value: HDiaryDestination.allMomentsScreen) {
          recentContent
        }
      }
    }

    @ViewBuilder
    private var recentContent: some View {
      HStack {
        Text(DiaryStringKey.Moment.moreRemainingMomentLabel)
          .font(.title2)
          .fontDesign(.rounded)
          .foregroundStyle(.primary)
          .bold()
        Spacer()
        Text(moreMomentCount.formatted())
          .foregroundStyle(.secondary)
      }
    }
  }
}

#if DEBUG
  @available(iOS 18.0, *)
  #Preview(traits: .modifier(SampleDataModifier())) { @MainActor in
    NavigationStack {
      List {
        MomentListScreen.RecentSection(moreMomentCount: 89)
      }
      .hDiaryNavigator()
    }
    .previewEnvironment()
  }

#endif
