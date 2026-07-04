//
//  MediaTests.swift
//
//
//  Created by tigerguo on 2023/12/9.
//

#if os(iOS)

  import UIKit
  import XCTest

  @testable import HMedia

  class MediaTest: XCTestCase {
    func testLargeImageResize() async throws {
      let image = UIImage(resource: .large)
      let imageData = try XCTUnwrap(image.pngData())
      let targetSize = CGSize(width: 300, height: 400)

      // test downsample to get image
      let thumbnail: UIImage = try await Task.detached {
        let resultImage: UIImage = try UIImage.downsample(imageData: imageData, to: targetSize)
        return resultImage
      }.value

      XCTAssertEqual(targetSize, thumbnail.size)

      // test downsample to get data
      let thumbnailData: Data = try await Task.detached {
        let data: Data = try UIImage.downsample(imageData: imageData, to: targetSize)
        XCTAssertFalse(Thread.isMainThread)
        return data
      }.value

      let downsampledImageFromData = try XCTUnwrap(UIImage(data: thumbnailData))
      XCTAssertEqual(targetSize, downsampledImageFromData.size)
    }

    func testSmallImageResize() async throws {
      let image = UIImage(resource: .tiny)
      let imageData = try XCTUnwrap(image.pngData())
      let targetSize = CGSize(width: 300, height: 400)

      // test downsample to get image
      let thumbnail: UIImage = try await Task.detached {
        let resultImage: UIImage = try UIImage.downsample(imageData: imageData, to: targetSize)
        XCTAssertFalse(Thread.isMainThread)
        return resultImage
      }.value

      XCTAssertEqual(image.size.applying(.init(scaleX: image.scale, y: image.scale)), thumbnail.size)

      // test downsample to get data
      let thumbnailData: Data = try await Task.detached {
        let data: Data = try UIImage.downsample(imageData: imageData, to: targetSize)
        return data
      }.value

      let downsampledImageFromData = try XCTUnwrap(UIImage(data: thumbnailData))
      XCTAssertEqual(image.size.applying(.init(scaleX: image.scale, y: image.scale)), downsampledImageFromData.size)
    }
  }
#endif
