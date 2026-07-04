//
//  TagLayout.swift
//  Libai
//
//  Created by huahuahu on 2022/3/20.
//

import Foundation
import UIKit

protocol TagLayoutDelegate: NSObjectProtocol {
  func textFor(_ indexPath: IndexPath) -> String
}

class TagLayout: UICollectionViewLayout {
  enum Constants {
    static let lineSpace: Double = 10
    static let horizontalMargin: Double = 10
    static let extraHorizontalPadding = TagCollectionView.Constants.padding.left + TagCollectionView.Constants.padding.right
    static let extrlVerticalPadding = TagCollectionView.Constants.padding.top + TagCollectionView.Constants.padding.bottom
  }

  weak var delegate: TagLayoutDelegate?

  private var previousBounds: CGRect = .zero
  private var sizeCache = [String: CGSize]()
  private var attributeCache = [IndexPath: UICollectionViewLayoutAttributes]()

  private var contentWidth: Double {
    guard let collectionView = collectionView else {
      return 0
    }
    let insets = collectionView.contentInset
    return collectionView.bounds.width - (insets.left + insets.right)
  }

  private var contentHeight: Double = 0

  override var collectionViewContentSize: CGSize {
    CGSize(width: contentWidth, height: contentHeight)
  }

  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    var visibleLayoutAttributes: [UICollectionViewLayoutAttributes] = []

    // Loop through the cache and look for items in the rect
    for attributes in attributeCache.values {
      if attributes.frame.intersects(rect) {
        visibleLayoutAttributes.append(attributes)
      }
    }
    return visibleLayoutAttributes
  }

  override func layoutAttributesForItem(at indexPath: IndexPath)
    -> UICollectionViewLayoutAttributes? {
    attributeCache[indexPath]
  }

  override func prepare() {
    hLog("\(String(describing: collectionView?.frame))", scenerio: .tagColltionView)
    guard attributeCache.isEmpty, let collectionView = collectionView, collectionView.numberOfSections > 0, collectionView.bounds.width > 0 else {
      return
    }

    var xOffSet: Double = 0 // possible next start
    var yOffSet: Double = 0 // possible next start

    contentHeight = 0
    let itemsCount = collectionView.numberOfItems(inSection: 0)
    for index in 0 ..< itemsCount {
      let indexPath = IndexPath(row: index, section: 0)
      if let text = delegate?.textFor(indexPath) {
        let size = {
          sizeCache[text] ?? text.rectUsing(TagCollectionView.Constants.font)

        }()
        sizeCache[text] = size
        // Should turn to next line
        if xOffSet + size.width + Constants.extraHorizontalPadding > contentWidth {
          yOffSet += size.height + Constants.lineSpace + Constants.extrlVerticalPadding
          xOffSet = 0
        }
        else {}

        let layoutAttribute = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        layoutAttribute.frame = CGRect(x: xOffSet, y: yOffSet, width: size.width + Constants.extraHorizontalPadding, height: size.height + Constants.extraHorizontalPadding).integral
        attributeCache[indexPath] = layoutAttribute
        xOffSet += size.width + Constants.extraHorizontalPadding + Constants.horizontalMargin

        contentHeight = max(contentHeight, layoutAttribute.frame.maxY)
      }
    }

    hLog("\(contentHeight), \(attributeCache.values.map(\.frame))", scenerio: .tagColltionView)

    // calculate layout Attribute
  }

  override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
    defer {
      previousBounds = newBounds
    }
    if previousBounds.width == newBounds.width {
      return false
    }
    else {
      hLog("\(newBounds)", scenerio: .tagColltionView)
      attributeCache.removeAll()
      return true
    }
  }

//
//  override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
//    hLog("\(context)", scenerio: .tagColltionView)
//
//    super.invalidateLayout(with: context)
//  }

//    override func invalidateLayout() {
//        hLog("invalidateLayout", scenerio: .tagColltionView)
//
//        super.invalidateLayout()
//    }
}
