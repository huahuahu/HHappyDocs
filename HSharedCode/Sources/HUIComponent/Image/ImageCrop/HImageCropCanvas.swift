#if os(iOS)
  import UIKit

  /// Insets make the circle, rather than the screen edges, the scroll view's content boundary.
  final class HImageCropCanvas: UIView, UIScrollViewDelegate {
    let scrollView = UIScrollView()
    private let imageView: UIImageView
    private let image: UIImage
    private let maximumCropSize: CGSize
    private let shade = CAShapeLayer()
    private(set) var cropRect = CGRect.zero
    private var layoutSize = CGSize.zero
    var reduceMotion = false {
      didSet {
        scrollView.bounces = !reduceMotion
        scrollView.bouncesZoom = !reduceMotion
      }
    }

    init(image: UIImage, maximumCropSize: CGSize) {
      self.image = image
      self.maximumCropSize = maximumCropSize
      imageView = UIImageView(image: image)
      super.init(frame: .zero)
      backgroundColor = .white
      scrollView.delegate = self
      scrollView.contentInsetAdjustmentBehavior = .never
      scrollView.showsHorizontalScrollIndicator = false
      scrollView.showsVerticalScrollIndicator = false
      scrollView.alwaysBounceHorizontal = true
      scrollView.alwaysBounceVertical = true
      scrollView.bouncesZoom = true
      scrollView.scrollsToTop = false
      imageView.frame = CGRect(origin: .zero, size: image.size)
      imageView.backgroundColor = .white
      imageView.isAccessibilityElement = false
      scrollView.addSubview(imageView)
      addSubview(scrollView)
      shade.fillRule = .evenOdd
      shade.fillColor = UIColor.black.withAlphaComponent(0.55).cgColor
      layer.addSublayer(shade)
      configureAccessibility()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    override func layoutSubviews() {
      super.layoutSubviews()
      let available = bounds.inset(by: safeAreaInsets)
      let side = max(1, min(maximumCropSize.width, maximumCropSize.height, available.width - 48, available.height - 48))
      let nextCrop = CGRect(x: available.midX - side / 2, y: available.midY - side / 2, width: side, height: side)
      guard bounds.width > 0, bounds.height > 0, layoutSize != bounds.size || nextCrop != cropRect else { return }
      let previous = cropGeometry
      let relativeOffset = previous.map { CGSize(width: $0.offset.width / $0.viewport.width, height: $0.offset.height / $0.viewport.height) } ?? .zero
      cropRect = nextCrop
      layoutSize = bounds.size
      scrollView.frame = bounds
      scrollView.contentInset = UIEdgeInsets(top: cropRect.minY, left: cropRect.minX, bottom: bounds.maxY - cropRect.maxY, right: bounds.maxX - cropRect.maxX)
      let minimum = max(side / max(image.size.width, 1), side / max(image.size.height, 1))
      scrollView.minimumZoomScale = minimum
      scrollView.maximumZoomScale = minimum * 5
      apply(HImageCropGeometry(
        imageSize: image.size, viewport: cropRect.size, scale: previous?.scale ?? 1,
        offset: CGSize(width: relativeOffset.width * side, height: relativeOffset.height * side)
      ))
      CATransaction.begin()
      CATransaction.setDisableActions(true)
      let path = UIBezierPath(rect: bounds)
      path.append(UIBezierPath(ovalIn: cropRect))
      shade.frame = bounds
      shade.path = path.cgPath
      CATransaction.commit()
    }

    var cropGeometry: HImageCropGeometry? {
      guard cropRect.width > 0, image.size.width > 0, image.size.height > 0 else { return nil }
      let frame = imageView.convert(imageView.bounds, to: self)
      let minimum = max(cropRect.width / image.size.width, cropRect.height / image.size.height)
      return HImageCropGeometry(
        imageSize: image.size, viewport: cropRect.size, scale: frame.width / image.size.width / minimum,
        offset: CGSize(width: frame.midX - cropRect.midX, height: frame.midY - cropRect.midY)
      )
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
      let relativeZoom = scrollView.zoomScale / max(scrollView.minimumZoomScale, .leastNonzeroMagnitude)
      accessibilityValue = Double(relativeZoom).formatted(.number.precision(.fractionLength(1))) + "×"
    }

    func reset() {
      apply(HImageCropGeometry(imageSize: image.size, viewport: cropRect.size, scale: 1, offset: .zero))
    }

    func zoom(by factor: CGFloat) {
      guard let crop = cropGeometry else { return }
      let scale = min(max(crop.scale * factor, 1), 5)
      // Auxiliary/VoiceOver zoom keeps the selected center fixed. Pinches use UIKit's finger anchor.
      let offset = CGSize(width: crop.offset.width * scale / crop.scale, height: crop.offset.height * scale / crop.scale)
      apply(HImageCropGeometry(imageSize: image.size, viewport: cropRect.size, scale: scale, offset: offset))
    }

    func move(x: CGFloat, y: CGFloat) {
      guard let crop = cropGeometry else { return }
      apply(HImageCropGeometry(
        imageSize: image.size, viewport: cropRect.size, scale: crop.scale,
        offset: CGSize(width: crop.offset.width + x * cropRect.width, height: crop.offset.height + y * cropRect.height)
      ))
    }

    func render() throws -> UIImage {
      guard let crop = cropGeometry else { throw CocoaError(.coderInvalidValue) }
      // A tap during deceleration/bounce commits the same valid region that is displayed here.
      apply(crop)
      return try crop.render(image)
    }

    private func apply(_ crop: HImageCropGeometry) {
      scrollView.setZoomScale(scrollView.minimumZoomScale * crop.scale, animated: false)
      let size = CGSize(width: image.size.width * scrollView.zoomScale, height: image.size.height * scrollView.zoomScale)
      scrollView.contentSize = size
      scrollView.setContentOffset(CGPoint(
        x: size.width / 2 - cropRect.midX - crop.offset.width,
        y: size.height / 2 - cropRect.midY - crop.offset.height
      ), animated: false)
    }

    override func accessibilityIncrement() { zoom(by: 1.25) }
    override func accessibilityDecrement() { zoom(by: 0.8) }

    private func configureAccessibility() {
      isAccessibilityElement = true
      accessibilityTraits = [.image, .adjustable]
      accessibilityIdentifier = "avatar.crop.preview"
      accessibilityLabel = String(localized: "avatarCrop.preview", bundle: .module)
      accessibilityHint = String(localized: "avatarCrop.instructions", bundle: .module)
      accessibilityCustomActions = [
        UIAccessibilityCustomAction(name: String(localized: "avatarCrop.moveLeft", bundle: .module)) { [weak self] _ in
          self?.move(x: -0.1, y: 0)
          return true
        },
        UIAccessibilityCustomAction(name: String(localized: "avatarCrop.moveRight", bundle: .module)) { [weak self] _ in
          self?.move(x: 0.1, y: 0)
          return true
        },
        UIAccessibilityCustomAction(name: String(localized: "avatarCrop.moveUp", bundle: .module)) { [weak self] _ in
          self?.move(x: 0, y: -0.1)
          return true
        },
        UIAccessibilityCustomAction(name: String(localized: "avatarCrop.moveDown", bundle: .module)) { [weak self] _ in
          self?.move(x: 0, y: 0.1)
          return true
        },
        UIAccessibilityCustomAction(name: String(localized: "avatarCrop.reset", bundle: .module)) { [weak self] _ in
          self?.reset()
          return true
        },
      ]
    }
  }
#endif
