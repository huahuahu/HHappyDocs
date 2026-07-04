//
//  WordCloudPoemFilterView.swift
//  Libai
//
//  Created by huahuahu on 2022/4/23.
//

import HUIComponent
import SwiftUI

struct WordCloudPoemFilterView: View {
  @Binding var filterModel: PoemFilterModel
  @Binding var isPresenting: Bool
  var onNewFilter: (PoemFilterModel) -> Void

  enum ButtonStyle {
    @ScaledMetric static var lineSpace = 8

    @ScaledMetric static var itemSpace = 30
  }

  private func genreView() -> some View {
    HFlowLayout(itemSpace: ButtonStyle.itemSpace, rowSpace: ButtonStyle.lineSpace, horizontalAlignment: .center) {
      ForEach(Genre.allCases) { genre in
        Button {
          if let index = filterModel.genreOptions.firstIndex(of: genre) {
            filterModel.genreOptions.remove(at: index)
          }
          else {
            filterModel.genreOptions.append(genre)
          }
        } label: {
          Text(genre.rawValue)
            .lineLimit(1)
        }
        .buttonStyle(TagButton(isSelected: filterModel.genreOptions.contains(genre), backgroundLevel: .secondary))
      }
    }
  }

  private func lifeStageView() -> some View {
    HFlowLayout(
      itemSpace: ButtonStyle.itemSpace,
      rowSpace: ButtonStyle.lineSpace,
      horizontalAlignment: .center
    ) {
      ForEach(LifeStage.allCases) { stage in
        Button {
          if let index = filterModel.lifeStage.firstIndex(of: stage) {
            filterModel.lifeStage.remove(at: index)
          }
          else {
            filterModel.lifeStage.append(stage)
          }
        } label: {
          Text(stage.rawValue)
            .lineLimit(1)
        }
        .buttonStyle(TagButton(isSelected: filterModel.lifeStage.contains(stage), backgroundLevel: .secondary))
      }
    }
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .center) {
        Button {
          onNewFilter(filterModel)
          isPresenting = false
        } label: {
          Text(PredefinedString.update)
            .font(.headline)
            .foregroundColor(Color.primaryLabel)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.secondaryBackground)
            .cornerRadius(10)
        }
        .padding([.top], 20)

        HStack(spacing: 10) {
          Text(PredefinedString.genre)
            .font(.headline)
          Spacer()
          Button(PredefinedString.restore) {
            filterModel.genreOptions = []
          }
          .foregroundColor(Color.primaryLabel)
          .padding(.horizontal, 10)
          .padding(.vertical, 5)
          .font(.callout)
          .background(Color.secondaryBackground)
          .cornerRadius(10)
        }
        .padding([.horizontal])

        genreView()
          .padding(.vertical, 10)
          .background(Color.secondaryBackground)
          .cornerRadius(10)

        HStack {
          Text(PredefinedString.lifeStage)
            .font(.headline)
          Spacer()
          Button(PredefinedString.restore) {
            filterModel.lifeStage = []
          }
          .font(.callout)
          .foregroundColor(Color.primaryLabel)
          .padding(.horizontal, 10)
          .padding(.vertical, 5)
          .font(.callout)
          .background(Color.secondaryBackground)
          .cornerRadius(10)
        }
        .padding([.horizontal])

        lifeStageView()
          .padding(.vertical, 10)
          .background(Color.secondaryBackground)
          .cornerRadius(10)
      }
      .padding()
    }
    .background(Color.primaryBackground)
  }
}

struct WordCloudPoemFilterView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      WordCloudPoemFilterView(
        filterModel: .constant(.init(genreOptions: [.七言古诗], lifeStage: [])),
        isPresenting: .constant(true)
      ) { _ in
      }
      WordCloudPoemFilterView(
        filterModel: .constant(.init(genreOptions: [.七言古诗], lifeStage: [])),
        isPresenting: .constant(true)
      ) { _ in
      }
      .environment(\.colorScheme, .dark)
    }
  }
}
