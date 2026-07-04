//
//  UIIndexView.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/4/12.
//

import UIKit

// MARK: - 自定义IndexView

class CustomIndexView: UIView {
  typealias SimpleCallBackWithInt = (_ index: Int) -> Void
  var selectedSection: SimpleCallBackWithInt?

  private var tipLabel: UILabel!
  private var selfSize: CGSize = .zero

  var indexTitles = [String]() {
    willSet {
      clear()
    }
    didSet {
      setupLabels()
    }
  }

  private var itemHeight: Double = 20
  private var itemWidth: Double = 40
  private var tipLabelWidth: Double = 60

  private var tag11 = 11_111
  private let fontSize = UIFont.systemFont(ofSize: 16)
  private let animationDuration: TimeInterval = 0.25
  var containerHeight: Double = 0 {
    didSet {
      hLog("containerHeight update \(containerHeight)", scenerio: .ui)
      updateIsHidden()
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
  }

  convenience init(frame: CGRect = CGRect.zero, indexTitles: [String], containerHeight: Double) {
    dataLog("init \(indexTitles.count)")
    self.init(frame: frame)
    self.containerHeight = containerHeight
    self.indexTitles = indexTitles
    setupUI()
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func clear() {
    selectedSection = nil
    for i in 0 ..< indexTitles.count {
      if let label = viewWithTag(tag11 + i) {
        label.removeFromSuperview()
      }
    }
  }

  func setupUI() {
    backgroundColor = UIColor.secondarySystemBackground
    setupLabels()
    setupTipLabel()
  }

  func setupTipLabel() {
    tipLabel = UILabel(frame: CGRect(x: -tipLabelWidth - 20, y: 0, width: tipLabelWidth, height: tipLabelWidth))
    tipLabel.font = UIFont.systemFont(ofSize: 32)
    tipLabel.textAlignment = .center
    tipLabel.textColor = UIColor.tintColor
    tipLabel.backgroundColor = UIColor.secondarySystemBackground
    tipLabel.layer.cornerRadius = tipLabelWidth * 0.5
    tipLabel.layer.masksToBounds = true
    tipLabel.alpha = 0
    addSubview(tipLabel)
  }

  func setupLabels() {
    let itemX: Double = 0
    var itemY: Double = 0
    for i in 0 ..< indexTitles.count {
      let label = UILabel(frame: CGRect(x: itemX, y: itemY, width: itemWidth, height: itemHeight))
      label.text = indexTitles[i]
      label.tag = tag11 + i
      label.textAlignment = .center
      label.textColor = UIColor.label
      label.font = fontSize

      addSubview(label)

      itemY += itemHeight

      if i == indexTitles.count - 1 {
        frame.size.height = itemY
      }
    }

    frame = CGRect(x: 0, y: 0, width: itemWidth, height: itemY)
//    center.y = UIScreen.main.bounds.height * 0.5
    selfSize = frame.size
  }

  private func updateIsHidden() {
    if selfSize.height > containerHeight {
      isHidden = true
    }
    else {
      isHidden = false
    }
  }

  override var intrinsicContentSize: CGSize {
    selfSize
  }

  func showTipsLabel(section: Int, centerY: Double) {
    guard let tipLabel = tipLabel else { return }

    selectedSection?(section)
    tipLabel.text = indexTitles[section]
    tipLabel.center.y = centerY

    UIView.animate(withDuration: animationDuration, animations: {
      tipLabel.alpha = 1

    })
  }

  func panAnimationWithTouches(touches: Set<UITouch>) {
    guard let touch = touches.first else { return }
    let point = touch.location(in: self)
    for i in 0 ..< indexTitles.count {
      if let label = viewWithTag(tag11 + i) {
        if label.frame.contains(point) {
          showTipsLabel(section: i, centerY: label.center.y)
        }
      }
    }
  }

  override var frame: CGRect {
    get {
      super.frame
    }
    set {
      super.frame = newValue
    }
  }

  override func layoutSubviews() {
    dataLog("self \(frame)")
    super.layoutSubviews()
  }

  func panAnimationFinished() {
    guard let tipLabel = tipLabel else { return }

    UIView.animate(withDuration: animationDuration, animations: {
      tipLabel.alpha = 0

    })
  }

  override func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent?) {
    panAnimationWithTouches(touches: touches)
  }

  override func touchesMoved(_ touches: Set<UITouch>, with _: UIEvent?) {
    panAnimationWithTouches(touches: touches)
  }

  override func touchesCancelled(_: Set<UITouch>, with _: UIEvent?) {
    panAnimationFinished()
  }

  override func touchesEnded(_: Set<UITouch>, with _: UIEvent?) {
    panAnimationFinished()
  }

  deinit {
    dataLog("deinit")
    self.tipLabel.removeFromSuperview()
    self.removeFromSuperview()
    self.selectedSection = nil
  }
}
