//
//  UIImage+util.swift
//  Libai (iOS)
//
//  Created by tigerguo on 2022/4/27.
//

import CoreImage
import Foundation
import SwiftUI
import UIKit

extension UIImage {
  /* *  @param inputMsg 二维码保存的信息
   *  @param fgImage  前景图片  */
  static func generateCode(inputMsg: String, fgImage _: UIImage?) -> UIImage? {
    let strData = inputMsg.data(using: .utf8, allowLossyConversion: false)
    // 创建一个二维码的滤镜
    guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
    qrFilter.setValue(strData, forKey: "inputMessage")
    qrFilter.setValue(inputMsg.count <= 150 ? "L" : "H", forKey: "inputCorrectionLevel")
    let qrCIImage = qrFilter.outputImage
    // 创建一个颜色滤镜,黑白色
    guard let colorFilter = CIFilter(name: "CIFalseColor") else { return nil }
    colorFilter.setDefaults()
    colorFilter.setValue(qrCIImage, forKey: "inputImage")
    colorFilter.setValue(CIColor.black, forKey: "inputColor0")
    colorFilter.setValue(CIColor.white, forKey: "inputColor1")

    guard let outputImage = colorFilter.outputImage else { return nil }
    let scale = 10.0
    let image_tr = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

    // https://stackoverflow.com/a/58240965/2739854
//      I guess the problem is that your CIImage is not actually "produced". You see, a CIImage is just a recipe for an image that needs to be rendered by a CIContext into an actual bitmap image.
//
//      The (poorly documented) convenient initializer UIImage(ciImage:) only works if the destination you assign the image to understands that the pixels of the UIImage are not yet there and need to be rendered first. UIImageView could handle this, but it seems SwiftUI's Image doesn't.
//
//      What you need to do is to create a CIContext (once, maybe as a property of your view) and use it to render your barcode image into a bitmap like this:
    let ciContext = CIContext()
    if let cgImage = ciContext.createCGImage(image_tr, from: image_tr.extent) {
      let qrImage = UIImage(cgImage: cgImage)
      return qrImage
    }
    return nil
  }

  func addLogo(theme: Theme? = .auto) -> UIImage {
    let size = CGSize(
      width: size.width,
      height: size.height + ImageLogoView.logoPadding * 2 + LogoView.height
    )
    let image = ImageLogoView(image: self)
      .theme(theme)
      .snapshot(size)
    return image
  }
}

extension UIImage {
  static let appQRCodeImage: UIImage = {
    let image = UIImage.generateCode(inputMsg: PredefinedString.appDownloadURL, fgImage: nil)
    return image!
  }()
}
