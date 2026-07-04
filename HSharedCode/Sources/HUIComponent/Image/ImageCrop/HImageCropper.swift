//
//  HImageCropper.swift
//  HDiary
//
//  Created by tigerguo on 2023/7/7.
//
// https://www.youtube.com/watch?v=1Fz86eQjxus
#if os(iOS)

  import OSLog
  import SwiftUI

  /// A view to crop ui image
  public struct HImageCropper: View {
    public init(
      originalImage: UIImage,
      imageSize: CGSize,
      onCropFinish: @escaping (UIImage?) -> Void
    ) {
      self.originalImage = originalImage
      self.imageSize = imageSize
      self.onCropFinish = onCropFinish
    }

    let logger = Logger(subsystem: "HUIComponent", category: "HImageCropper")

    let originalImage: UIImage

    /// The cropper size in screen
    let imageSize: CGSize
    let onCropFinish: (UIImage?) -> Void
    private let cropViewSpaceName = UUID().uuidString

    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastStoredOffset: CGSize = .zero

    @GestureState private var isInteracting = false

    public var body: some View {
      NavigationStack {
        imageView()
          .navigationTitle(Text(HUIComponentString.crop.hDocLocalized()))
          .navigationBarTitleDisplayMode(.inline)
          .toolbarBackground(.visible, for: .navigationBar)
          .toolbarBackground(.black, for: .navigationBar)
          .toolbarColorScheme(.dark, for: .navigationBar)
          .toolbar(content: {
            toolbar
          })
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(
            Color.black
              .ignoresSafeArea()
          )
      }
    }

    @ViewBuilder
    private func imageView() -> some View {
      // Proxy size is the cropper view's size
      GeometryReader { cropViewPointProxy in
        Image(uiImage: originalImage)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .overlay(content: {
            // Proxy size is the scaled image's size
            GeometryReader { proxy in
              let rect = proxy.frame(in: .named(cropViewSpaceName))
              // swiftlint:disable:next redundant_discardable_let
              let _ = logger.debug("original image \(originalImage) rect is \(String(describing: rect)), proxy size \(String(describing: proxy.size)), outer proxy size \(String(describing: cropViewPointProxy.size)), offset is \(String(describing: offset))")
              Color.clear
                .onChange(of: isInteracting, { _, newValue in
                  withAnimation {
                    if rect.minX > 0 {
                      logger.debug("image too right")
                      offset.width -= rect.minX
                      #if os(visionOS)
                      #else
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                      #endif
                    }

                    if rect.minY > 0 {
                      logger.debug("image too down")
                      offset.height -= rect.minY
                      #if os(visionOS)
                      #else
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                      #endif
                    }

                    if rect.maxX < cropViewPointProxy.size.width {
                      logger.debug("image too left")
                      offset.width = rect.minX - offset.width
                      #if os(visionOS)
                      #else
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                      #endif
                    }

                    if rect.maxY < cropViewPointProxy.size.height {
                      logger.debug("image too up")
                      offset.height = rect.minY - offset.height
                      #if os(visionOS)
                      #else
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                      #endif
                    }
                  }

                  if !newValue {
                    onGestureEnd()
                  }
                })
            }
          })
          .frame(width: cropViewPointProxy.size.width, height: cropViewPointProxy.size.height)
      }

      .scaleEffect(scale)
      .offset(offset)
      .coordinateSpace(.named(cropViewSpaceName))
      .gesture(
        DragGesture()
          .updating($isInteracting, body: { _, out, _ in
            out = true
          }).onChanged({ value in
            onDragChange(value)
          })
      )
      .gesture(
        MagnifyGesture()
          .updating($isInteracting, body: { _, out, _ in
            out = true
          }).onChanged({ value in
            onMagnifyGestureChange(value)
          }).onEnded({ _ in
            withAnimation {
              if scale < 1 {
                scale = 1
                lastScale = 0
              }
              else {
                lastScale = scale - 1
              }
            }
          })
      )
      .frame(width: imageSize.width, height: imageSize.height)
      .clipped()
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
      ToolbarItem(placement: .cancellationAction) {
        Button(action: {
          dismiss()
        }, label: {
          Image(systemName: "xmark")
            .font(.callout)
            .fontWeight(.semibold)

        })
      }

      ToolbarItem(placement: .confirmationAction) {
        Button(action: {
          Task { @MainActor in
            let renderer = ImageRenderer(content: imageView())
            renderer.proposedSize = .init(imageSize)
            // set scale to 10 so the result image isn't too small
            renderer.scale = 10.0
            onCropFinish(renderer.uiImage)
          }

          dismiss()
        }, label: {
          Image(systemName: "checkmark")
            .font(.callout)
            .fontWeight(.semibold)
        })
      }
    }

    private func onDragChange(_ value: DragGesture.Value) {
      let translation = value.translation

      offset = CGSize(width: translation.width + lastStoredOffset.width, height: translation.height + lastStoredOffset.height)
    }

    private func onMagnifyGestureChange(_ value: MagnifyGesture.Value) {
      let updatedScale = value.magnification + lastScale
      scale = max(1.0, updatedScale)
    }

    private func onGestureEnd() {
      lastStoredOffset = offset
    }
  }

  #if DEBUG

    #Preview {
      Image(uiImage: .actions)
        .sheet(isPresented: .constant(true), content: {
          HImageCropper(originalImage: .add, imageSize: .init(width: 300, height: 300), onCropFinish: { _ in
            print("")
          })

        })
    }

  #endif
#endif
