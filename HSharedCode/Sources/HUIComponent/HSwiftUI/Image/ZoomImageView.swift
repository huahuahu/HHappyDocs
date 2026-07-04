//
//  ZoomImageView.swift
//  HUIComponent
//
//  Created by huahuahu on 2022/2/5.
//

#if os(iOS)

  import Foundation
  import SwiftUI
  import UIKit

  // Reference: https://tinyurl.com/y2aamlqd and https://tinyurl.com/y62jzxsv
  public struct ZoomableImageView: UIViewRepresentable {
    public init(image: UIImage) {
      self.image = image
    }

    var image: UIImage

    public func makeUIView(context: Context) -> UIScrollView {
      // set up the UIScrollView
      let scrollView = UIScrollView()
      scrollView.delegate = context.coordinator // for viewForZooming(in:)
      scrollView.maximumZoomScale = 8
      scrollView.minimumZoomScale = 1
      scrollView.bouncesZoom = true
      scrollView.bounces = true
      scrollView.showsVerticalScrollIndicator = false
      scrollView.showsHorizontalScrollIndicator = false
      scrollView.contentInsetAdjustmentBehavior = .never

      let imageView = context.coordinator.imageView
      imageView.frame = scrollView.bounds
      scrollView.addSubview(imageView)
      return scrollView
    }

    public func makeCoordinator() -> Coordinator {
      let imageView = UIImageView(image: image)
      imageView.contentMode = .scaleAspectFit
      imageView.translatesAutoresizingMaskIntoConstraints = true
      imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      return Coordinator(imageView: imageView)
    }

    public func updateUIView(_: UIScrollView, context: Context) {
      // update the hosting controller\'s SwiftUI content
      // TODO: Reset the zoom, so you need to get the scrollView as well
      context.coordinator.imageView.image = image
      // swiftlint:disable:next force_cast
      let scrollView = context.coordinator.imageView.superview as! UIScrollView
      scrollView.zoomScale = 1.0
    }

    // MARK: - Coordinator

    public class Coordinator: NSObject, UIScrollViewDelegate {
      var imageView: UIImageView

      init(imageView: UIImageView) {
        self.imageView = imageView
      }

      public func viewForZooming(in _: UIScrollView) -> UIView? {
        imageView
      }

      public func scrollViewDidZoom(_: UIScrollView) {
        centerImage()
      }

      func centerImage() {
        // center the zoom view as it becomes smaller than the size of the screen
        let boundsSize = imageView.bounds.size
        var frameToCenter = imageView.frame

        // center horizontally
        if frameToCenter.size.width < boundsSize.width {
          frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2
        }
        else {
          frameToCenter.origin.x = 0
        }

        // center vertically
        if frameToCenter.size.height < boundsSize.height {
          frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2
        }
        else {
          frameToCenter.origin.y = 0
        }

        imageView.frame = frameToCenter
      }
    }
  }

#endif
