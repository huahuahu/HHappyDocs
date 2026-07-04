//
//  IndexView.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/4/10.
//

import SwiftUI

struct IndexView: UIViewRepresentable {
//  internal init(containerHeight: Binding<CGFloat>, indexItems: [IndexItem]) {
//    _containerHeight = containerHeight
//    self.indexItems = indexItems
//    hLog("index create, size \(containerHeight)", scenerio: .ui)
//  }

  func makeCoordinator() -> Coor {
    Coor()
  }

  @Binding var containerHeight: Double
  @Binding var indexItems: [IndexItem]

  func makeUIView(context _: Context) -> CustomIndexView {
    hLog("makeUIView containerHeight \(containerHeight)", scenerio: .ui)

    let indexView = CustomIndexView(indexTitles: indexItems.map(\.displayText), containerHeight: containerHeight)
    indexView.selectedSection = { index in
      hLog("selected index \(index)", scenerio: .ui)
      indexItems[index].onTap()
    }
//      uiViewI = indexView
    return indexView
  }

  func updateUIView(_ uiView: CustomIndexView, context _: Context) {
//        context.coordinato
    uiView.containerHeight = containerHeight
    uiView.indexTitles = indexItems.map(\.displayText)
    uiView.selectedSection = { index in
      hLog("selected index \(index)", scenerio: .ui)
      indexItems[index].onTap()
    }
  }

  func sizeThatFits(_ proposal: ProposedViewSize, uiView: CustomIndexView, context: Context) -> CGSize? {
    uiView.intrinsicContentSize
  }

  static func dismantleUIView(_: CustomIndexView, coordinator: Coor) {
    coordinator.uiViewI?.removeFromSuperview()
  }

  class Coor {
    var uiViewI: CustomIndexView?
  }
}
