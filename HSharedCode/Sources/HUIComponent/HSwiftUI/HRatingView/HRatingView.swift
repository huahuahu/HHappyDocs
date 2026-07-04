//
//  SwiftUIView.swift
//
//
//  Created by tigerguo on 2023/7/22.
//
#if os(iOS)
  import HLocalization
  import SwiftUI

  public struct HRatingView: View {
    public init(model: HRatingModel,
                rating: Binding<HRating?>) {
      self.model = model
      self._rating = rating
    }

    let model: HRatingModel
    @Binding private var rating: HRating?

    public var body: some View {
      HStack {
        if model.label.isEmpty == false {
          Text(model.label)
        }

        ForEach(HRating.minStar ... HRating.maxStar, id: \.self) { rating in
          image(for: rating)
            .foregroundColor(foregroundColor(for: rating))
            .onTapGesture {
              self.rating = rating
            }
        }
        if model.canEdit {
          Spacer()
          Button(HLocalizedString.reset) {
            self.rating = nil
          }
          .buttonStyle(.borderedProminent)
          .buttonBorderShape(.capsule)
        }
      }
    }

    private func foregroundColor(for rating: HRating) -> Color {
      guard let currentRating = self.rating else {
        return model.offColor
      }
      return rating > currentRating ? model.offColor : model.onColor
    }

    private func image(for rating: HRating) -> Image {
      guard let currentRating = self.rating else {
        return model.offImage ?? model.onImage
      }
      if rating > currentRating {
        return model.offImage ?? model.onImage
      }
      else {
        return model.onImage
      }
    }
  }

  struct HRatingViewr_Previews: PreviewProvider {
    static var previews: some View {
      Group {
        HRatingView(model: .preview, rating: .constant(.fourStars))
        HRatingView(model: .preview, rating: .constant(nil))
        Form {
          Section {
            HRatingView(model: HRatingModel(canEdit: true), rating: .constant(nil))
//                    .listRowBackground(Color.clear)
          }
        }
      }
    }
  }

#endif
