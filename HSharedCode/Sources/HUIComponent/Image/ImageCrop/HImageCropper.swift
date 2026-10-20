#if os(iOS)
  import SwiftUI

  /// A full-screen avatar crop with native panning and pinch-to-zoom.
  public struct HImageCropper: View {
    private let originalImage: UIImage
    private let imageSize: CGSize
    private let onCropFinish: (UIImage) throws -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var editor = HImageCropEditor()
    @State private var showsError = false

    public init(originalImage: UIImage, imageSize: CGSize, onCropFinish: @escaping (UIImage) throws -> Void) {
      self.originalImage = originalImage
      self.imageSize = imageSize
      self.onCropFinish = onCropFinish
    }

    public var body: some View {
      NavigationStack {
        HImageCropCanvasView(image: originalImage, maximumCropSize: imageSize, editor: editor, reduceMotion: reduceMotion)
          .ignoresSafeArea()
          .navigationTitle(Text("avatarCrop.title", bundle: .module))
          .navigationBarTitleDisplayMode(.inline)
          .toolbarBackground(.hidden, for: .navigationBar)
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button { dismiss() } label: { Text("avatarCrop.cancel", bundle: .module) }
                .accessibilityIdentifier("avatar.crop.cancel")
            }
            ToolbarItem(placement: .primaryAction) {
              Menu {
                Button { editor.canvas?.zoom(by: 1.25) } label: {
                  Label { Text("avatarCrop.zoomIn", bundle: .module) } icon: { Image(systemName: "plus.magnifyingglass") }
                }
                Button { editor.canvas?.zoom(by: 0.8) } label: {
                  Label { Text("avatarCrop.zoomOut", bundle: .module) } icon: { Image(systemName: "minus.magnifyingglass") }
                }
                Button { editor.canvas?.reset() } label: {
                  Label { Text("avatarCrop.reset", bundle: .module) } icon: { Image(systemName: "arrow.counterclockwise") }
                }
              } label: {
                Label { Text("avatarCrop.adjust", bundle: .module) } icon: { Image(systemName: "ellipsis") }
              }
              .accessibilityIdentifier("avatar.crop.adjust")
            }
            ToolbarItem(placement: .confirmationAction) {
              Button(action: finish) { Text("avatarCrop.done", bundle: .module) }
                .accessibilityIdentifier("avatar.crop.done")
            }
          }
          .alert(Text("avatarCrop.failureTitle", bundle: .module), isPresented: $showsError) {
            Button(action: finish) { Text("avatarCrop.retry", bundle: .module) }
            Button(role: .cancel) {} label: { Text("avatarCrop.keepEditing", bundle: .module) }
          } message: {
            Text("avatarCrop.failureMessage", bundle: .module)
          }
      }
      .preferredColorScheme(.dark)
    }

    private func finish() {
      do {
        guard let canvas = editor.canvas else { throw CocoaError(.coderInvalidValue) }
        try onCropFinish(canvas.render())
        dismiss()
      }
      catch { showsError = true }
    }
  }
#endif
