//
//  MomentItemView.swift
//  HDiary
//
//  Created by tigerguo on 2023/7/23.
//

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
    ZStack {
      Color.clear
      NavigationLink(value: HDiaryDestination.moment(moment, editEnabled: true)) {
        HStack {
          VStack(alignment: .leading, content: {
            Text(moment.title)
              .lineLimit(1)

            bottomView
          })
          .padding(.horizontal)
          Spacer()
        }
      }
    }
    .padding()
    .background(.regularMaterial, in: .rect(cornerRadius: backgroundConerRadius))
  }

  private var bottomView: some View {
    HStack {
      HRatingView(
        model: HRatingModel(onColor: .accentColor),
        rating: .constant(HRating(rawValue: moment.rating))
      )
      .allowsHitTesting(false)
      .scaleEffect(0.65, anchor: .leading)
      Spacer()
      Text(moment.timestamp, style: .date)
        .font(.caption)
    }
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
