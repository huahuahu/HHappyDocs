#if os(iOS)

  import CoreImage
  import Foundation
  import ImageIO
  import UniformTypeIdentifiers

  /// 将头像原图缩小为适合 Widget 存储与展示的图片，沿用原图格式。
  nonisolated enum WidgetAvatarThumbnailer {
    // CIContext 是 Core Image 执行图像处理和编码时使用的上下文，复用它可以减少重复创建资源的开销。
    // 每张头像只处理一次，因此不缓存中间处理结果；这不会改变输出图片的尺寸、位深或编码质量。
    private static let imageContext = CIContext(options: [.cacheIntermediates: false])

    /// 从原图文件数据生成缩略图文件数据，供 Widget 快照保存。
    ///
    /// 这里有两个不同的概念：
    /// - 文件格式：HEIC、JPEG、PNG 等，决定图片如何编码、压缩和保存。
    /// - 像素图像：解码后每个位置的颜色，缩放操作处理的是这些像素。
    ///
    /// 处理流程是「读取原格式 → 按目标尺寸解码/缩小 → 用原格式重新编码」。
    /// `maxPixelSize` 表示最长边的像素数，不是 SwiftUI 的 point；例如 512 × 256 缩为 64 × 32。
    /// 同格式仍需要重新编码，因此不代表无损复制。这里只处理第一张图，不负责复制全部元数据或动画帧。
    /// 原图缺失、无法解码、尺寸参数无效或编码失败时返回 nil，由调用方处理缺少头像的情况。
    @concurrent
    static func thumbnailData(from data: Data?, maxPixelSize: Int) async -> Data? {
      // data 是已编码的图片文件内容，不能直接当成一组 RGB 颜色来缩小。
      // CGImageSource 相当于图片读取器：用于识别格式、读取属性，以及按需解码图像。
      // 创建读取器不等于已经把整张原图展开到内存中。
      // type 来自文件内容，例如 public.heic；后面沿用它，避免把所有图片都转成 JPEG。
      guard let data, maxPixelSize > 0,
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let type = CGImageSourceGetType(source)
      else {
        return nil
      }

      let options: [CFString: Any] = [
        // 从图像内容生成缩略图，避免依赖文件里可能附带的、尺寸或质量不合适的预览小图。
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        // 应用照片记录的旋转/镜像方向，让输出像素本身就是正确朝向。
        // 手机竖拍照片的像素可能横着存放，再通过方向信息告诉显示端如何旋转。
        kCGImageSourceCreateThumbnailWithTransform: true,
        // 在创建缩略图时完成解码，避免把这部分工作推迟到后续使用图像时。
        kCGImageSourceShouldCacheImmediately: true,
        // 设置缩略图最长边的像素上限。
        // ImageIO 会保持原图宽高比，例如上限为 64 时，512 × 256 会缩成 64 × 32。
        kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
      ]
      // 让 ImageIO 按目标尺寸生成像素图，减少先完整解码原图、再手动缩小带来的内存开销。
      // 例如 3000 × 3000 的 RGBA8 位图约占 34 MiB，而 64 × 64 只需约 16 KiB。
      // 这是像素展开后的大小，与磁盘上 HEIC/JPEG 文件的压缩大小是两回事。
      // image 是 CGImage（像素及其颜色信息），此时还没有生成可保存的 HEIC/JPEG/PNG 文件数据。
      guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
      else {
        return nil
      }

      if type == UTType.heic.identifier as CFString, image.bitsPerComponent > 8,
         let colorSpace = image.colorSpace {
        // 位深表示每个颜色分量的精细程度：8-bit 有 256 个等级，10-bit 有 1024 个等级。
        // 它与「有多少像素」独立，缩小尺寸不要求把 10-bit 同时降成 8-bit。
        // 某些 iOS 运行环境的 ImageIO HEIC 编码器无法接收这里返回的打包 10-bit 像素布局，
        // 会报 unexpected bitDepth / pixelFormat was not set，因此高位深 HEIC 改走 HEIF10 编码。
        // CIImage 是交给 Core Image 处理的图像表示，不是新的文件格式；最终输出仍是 10-bit HEIC。
        // 色彩空间规定颜色数值如何对应实际颜色；Display P3 能表示的部分颜色超出了 sRGB 范围。
        // 传入缩略图原有的 colorSpace，避免先转成 sRGB、丢失这些颜色后再保存。
        // 保留 10-bit 和 P3 不等于保留全部 HDR 信息；这里没有单独复制原文件的 HDR gain map 等数据。
        return try? imageContext.heif10Representation(
          of: CIImage(cgImage: image),
          colorSpace: colorSpace,
          // 0.8 是有损编码的质量参数，不是缩放比例，也不保证文件变成原大小的 80%。
          options: [CIImageRepresentationOption(rawValue: kCGImageDestinationLossyCompressionQuality as String): 0.8]
        )
      }

      // 其他图片交给 ImageIO 编码。output 是接收编码结果的内存缓冲区，这里不直接写磁盘。
      // 使用原来的 type：JPEG 仍为 JPEG，PNG 仍为 PNG，普通 8-bit HEIC 仍为 HEIC。
      // PNG 因此也能继续保存透明度；如果统一转成不支持透明通道的 JPEG，就会丢失透明信息。
      let output = NSMutableData()
      guard let destination = CGImageDestinationCreateWithData(
        output,
        type,
        // 只写入一张静态缩略图。
        1,
        nil
      ) else {
        // 当前环境无法创建该格式的编码器时，不悄悄改成另一种格式。
        return nil
      }

      // 把缩小后的像素交给编码器；沿用 CGImage 自带的色彩空间，不主动转成 sRGB。
      // 质量参数用于 JPEG/HEIC 等有损格式；PNG 仍使用自身的无损编码方式。
      CGImageDestinationAddImage(
        destination,
        image,
        [kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary
      )
      // AddImage 之后还需要 Finalize 完成编码。只有成功后，output 才可作为完整图片数据返回。
      // 编码器能创建不代表一定能处理所有像素布局，因此这里仍要检查失败情况。
      guard CGImageDestinationFinalize(destination) else {
        return nil
      }

      // 返回的是小尺寸图片的文件数据，后续可存入 Widget 快照，再由 UIImage 等解码显示。
      return output as Data
    }
  }

#endif
