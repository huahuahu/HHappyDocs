//
//  LifeSpanList.swift
//  Libai
//
//  Created by huahuahu on 2022/3/17.
//

import SwiftUI

struct LifeSpanList: View {
  @State var lifeSpans: [LifeSpan]
  @State private var editMode: EditMode = .active
  @State private var selections = Set<String>()

  @State private var isPresenting = false
  @EnvironmentObject var setting: Settings

  var selectionTips: some View {
    let tips = lifeSpans.count > 1 ? PredefinedString.selectLifeSpan : PredefinedString.noEnoughLifeSpanForCompare
    return Text(tips)
      .font(.caption)
  }

  @ViewBuilder
  var customEditButton: some View {
    if editMode == .active {
      Button {
        isPresenting = true
      } label: {
        Text(PredefinedString.compare)
      }
      .disabled(selections.count < 2)
    }
    else {
      Button {
        withAnimation {
          editMode = .active
        }
      } label: {
        Text(PredefinedString.select)
      }
    }
  }

  var body: some View {
    List(selection: $selections) {
      selectionTips
      LifeSpanCells(lifeSpans: $lifeSpans)
    }
    .task {
      if lifeSpans.count < 2 {
        editMode = .inactive
      }
    }
    .toolbar {
      customEditButton
        .disabled(lifeSpans.count < 2)
    }
    .environment(\.editMode, $editMode)
    .fullScreenCover(isPresented: $isPresenting) {
      LifeSpanChartView(isPresenting: $isPresenting, lifeSpans: lifeSpans.filter {
        selections.contains($0.id)
      })
      .theme(setting.pTheme)
    }
  }
}

struct LifeSpanList_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      NavigationView {
        LifeSpanList(lifeSpans: [.libai, .武则天])
          .navigationTitle("life span")
          .navigationBarTitleDisplayMode(.inline)
      }
      NavigationView {
        LifeSpanList(lifeSpans: [.libai])
          .navigationTitle("life span")
          .navigationBarTitleDisplayMode(.inline)
      }
    }
    .environmentObject(Settings.shared)
  }
}
