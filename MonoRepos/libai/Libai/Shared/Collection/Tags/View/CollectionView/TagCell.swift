//
//  TagCell.swift
//  Libai
//
//  Created by huahuahu on 2022/3/20.
//

import Foundation
import SwiftUI
import UIKit

class TagCell: UICollectionViewCell {
  private let label: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .preferredFont(forTextStyle: .body)
    label.backgroundColor = .secondarySystemBackground
    label.layer.cornerRadius = 5
    label.layer.masksToBounds = true
    label.textAlignment = .center
    return label
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    configView()
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func configView() {
    contentView.addSubview(label)
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      label.topAnchor.constraint(equalTo: contentView.topAnchor),
      label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  func updateTag(_ tag: String) {
    label.text = tag
  }
}
