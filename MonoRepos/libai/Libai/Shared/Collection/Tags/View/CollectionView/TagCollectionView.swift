//
//  TagCollectionView.swift
//  Libai
//
//  Created by huahuahu on 2022/3/20.
//
// Replaced by HFlowLayout

import Foundation
import SwiftUI

struct TagCollectionView: UIViewRepresentable {
  enum Constants {
    static let font = UIFont.preferredFont(forTextStyle: .body)
    static let padding = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
  }

  @Binding var selectedTag: String?

  var tags: [String]

  func makeUIView(context: Context) -> some UIView {
    hLog("makeUIVIew", scenerio: .tagColltionView)
    let layout = TagLayout()
    layout.delegate = context.coordinator
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.delegate = context.coordinator
    _ = context.coordinator.configDataSource(collectionView)
    return collectionView
  }

  func updateUIView(_: UIViewType, context: Context) {
    hLog("updateUIView)", scenerio: .tagColltionView)
    context.coordinator.updateTags(tags)
  }

  func makeCoordinator() -> Coordinator {
    hLog("makeCoordinator", scenerio: .tagColltionView)

    let coor = Coordinator(tags: tags, selectedTag: $selectedTag)
    return coor
  }

  class Coordinator: NSObject, UICollectionViewDelegate, TagLayoutDelegate {
    var tags: [String]
    var dataSource: UICollectionViewDiffableDataSource<String, String>!

    @Binding var selectedTag: String?

    init(tags: [String], selectedTag: Binding<String?>) {
      _selectedTag = selectedTag
      self.tags = tags
      super.init()
    }

    func configDataSource(_ collectionView: UICollectionView) -> UICollectionViewDiffableDataSource<String, String> {
      hLog("configDataSource", scenerio: .tagColltionView)

      let cellConfiguration = getCellConfiguration()
      dataSource = UICollectionViewDiffableDataSource<String, String>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
        collectionView.dequeueConfiguredReusableCell(using: cellConfiguration, for: indexPath, item: itemIdentifier)
      })

      updateTags(tags)
      return dataSource
    }

    func getCellConfiguration() -> UICollectionView.CellRegistration<TagCell, String> {
      hLog("getCellConfiguration", scenerio: .tagColltionView)

      return .init { cell, _, itemIdentifier in
        cell.updateTag(itemIdentifier)
      }
    }

    func updateTags(_ tags: [String]) {
      self.tags = tags
      hLog("new tags \(tags)", scenerio: .tagColltionView)
      var snapShot = NSDiffableDataSourceSnapshot<String, String>()
      snapShot.appendSections([""])
      snapShot.appendItems(tags, toSection: nil)

      dataSource.apply(snapShot)
    }

    func textFor(_ indexPath: IndexPath) -> String {
      tags[indexPath.row]
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
      let tag = tags[indexPath.row]
      selectedTag = tag
      let tagListView = TagPoemsListView(tag: tag)

      let targetVC = UIHostingController(rootView: tagListView)
      let currentVC = collectionView.vc
      currentVC?.navigationController?.pushViewController(targetVC, animated: true)
    }
  }
}
