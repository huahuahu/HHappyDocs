//
//  SearchResultFilterView.swift
//  Libai
//
//  Created by huahuahu on 2022/5/30.
//

import SwiftUI

struct SearchResultFilterView: View {
  @ScaledMetric private var margin = 15.0
  let allReasons: SearchMatchReason
  @Binding var selectedReason: SearchMatchReason

  @ScaledMetric private var verticalPadding = 10.0
  private func reasonView(for reason: SearchMatchReason) -> some View {
    Button {
      selectedReason = reason
    } label: {
      Text(reason.labelText)
    }
    .buttonStyle(TagButton(isSelected: reason == selectedReason))
  }

  var expandedReasons: [SearchMatchReason] {
    var expanded = allReasons.expand()
    if expanded.count > 1 {
      expanded.insert(.all, at: 0)
    }
    return expanded
  }

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: margin) {
        ForEach(expandedReasons) { reason in
          reasonView(for: reason)
        }
      }
      .padding([.horizontal])
      .padding(.vertical, verticalPadding)
//      .background(Color.secondaryBackground)
    }
  }
}

struct SearchResultFilterView_Previews: PreviewProvider {
  static var previews: some View {
    SearchResultFilterView(
      allReasons: [.all],
      selectedReason: .constant(.title)
    )
  }
}
