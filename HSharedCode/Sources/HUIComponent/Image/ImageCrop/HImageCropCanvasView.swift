#if os(iOS)
  import SwiftUI

  struct HImageCropCanvasView: UIViewRepresentable {
    let image: UIImage
    let maximumCropSize: CGSize
    let editor: HImageCropEditor
    let reduceMotion: Bool

    func makeUIView(context: Context) -> HImageCropCanvas {
      let canvas = HImageCropCanvas(image: image, maximumCropSize: maximumCropSize)
      editor.canvas = canvas
      return canvas
    }

    func updateUIView(_ canvas: HImageCropCanvas, context: Context) {
      canvas.reduceMotion = reduceMotion
    }
  }
#endif
