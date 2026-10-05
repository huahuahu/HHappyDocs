//
//  MomentItemView.swift
//  HDiary
//
//  Created by tigerguo on 2023/7/23.
//

#if os(iOS)

import Foundation
import HDiaryModel
import HUIComponent
import SwiftData
import SwiftUI

struct MomentItemView: View {
  init(moment: Moment) {
    self.moment = moment
  }

  @ScaledMetric private var backgroundConerRadius = 20.0
  private let moment: Moment
  var body: some View {
    MomentNavigationLink(moment: moment) {
      HStack {
        VStack(alignment: .leading, content: {
          Text(moment.title)
            .lineLimit(1)

          bottomView
        })
        .padding(.horizontal)
        Spacer()
      }
      .padding()
      .background(.regularMaterial, in: .rect(cornerRadius: backgroundConerRadius))
    }
  }

  private var bottomView: some View {
    ViewThatFits(in: .horizontal) {
      HStack {
        ratingView
        Spacer(minLength: 8)
        dateView
          .fixedSize(horizontal: true, vertical: false)
      }
      VStack(alignment: .leading, spacing: 4) {
        ratingView
        dateView
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var ratingView: some View {
    HRatingView(
      model: HRatingModel(onColor: .accentColor),
      rating: .constant(HRating(rawValue: moment.rating))
    )
    .font(.caption)
    .fixedSize()
    .allowsHitTesting(false)
  }

  private var dateView: some View {
    Text(moment.timestamp, style: .date)
      .font(.caption)
  }
}

#if DEBUG
  @available(iOS 18.0, *)
  #Preview("Edit", traits: .modifier(SampleDataModifier())) {
    @Previewable @Query var moments: [Moment]
    return VStack {
      Section {
        LazyVGrid(columns: [.init(.adaptive(minimum: 300))], content: {
          MomentItemView(moment: moments.first!)
          MomentItemView(moment: moments.dropFirst().first!)
        })
      } header: {
        Text(verbatim: "items")
      }
    }
  }

#endif

#endif
