//
//  TimeConstrainedMomentListView.swift
//  HDiary
//
//  Created by tigerguo on 2023/9/3.
//
#if os(iOS)

import HDiaryModel
import HUIComponent
import SwiftData
import SwiftUI

struct TimeConstrainedMoments: Hashable {
  let moments: [Moment]
  let timeRangeString: String
}

struct TimeConstrainedMomentListView: View {
  let timeConstrainedMoments: TimeConstrainedMoments
  var body: some View {
    List {
      ForEach(timeConstrainedMoments.moments) { moment in
        NavigationLink(value: HDiaryDestination.moment(moment, editEnabled: true)) {
          MomentListItemView(moment: moment)
        }
      }
    }
    .navigationTitle(Text(timeConstrainedMoments.timeRangeString))
    .navigationBarTitleDisplayMode(.inline)
  }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(SampleDataModifier())) {
  @Previewable @Query var moments: [Moment]
  let timeConstrainedMoments = TimeConstrainedMoments(moments: Array(moments.prefix(2)), timeRangeString: "recents")
  NavigationStack {
    TimeConstrainedMomentListView(timeConstrainedMoments: timeConstrainedMoments)
  }
}

#endif
