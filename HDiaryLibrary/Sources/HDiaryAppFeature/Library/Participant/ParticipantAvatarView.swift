#if os(iOS)
  import HDiaryModel
  import SFSafeSymbols
  import SwiftUI

  struct ParticipantAvatarView: View {
    let participant: Participant
    let size: CGFloat
    var supportsPreview = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale
    @State private var loader = ParticipantAvatarLoader()
    @State private var isPreviewingAvatar = false

    var body: some View {
      let request = ParticipantAvatarLoader.Request(
        participantID: participant.uuid,
        data: participant.avatar,
        maxPixelSize: max(1, Int((size * displayScale).rounded(.up)))
      )
      let presentation = loader.presentation(for: request)
      ZStack {
        if case let .image(image, _) = presentation {
          // Stored avatars can be photos or rasterized symbols; preserve their original colors.
          Image(uiImage: image)
            .renderingMode(.original)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            // Only transparent pixels reveal this backing; photos still fill the circle.
            .background(.white)
        }
        else {
          Circle()
            .fill(.tint)
            .opacity(colorScheme == .dark ? 0.17 : 0.1)
          if case .placeholder = presentation {
            if let initial = participant.displayName.first {
              Text(String(initial))
                .font(.system(size: size * 0.38, weight: .medium, design: .rounded))
            }
            else {
              Image(systemSymbol: .personFill)
                .font(.system(size: size * 0.4, weight: .medium))
            }
          }
        }
      }
      .foregroundStyle(.tint)
      .frame(width: size, height: size)
      .clipShape(Circle())
      .accessibilityHidden(true)
      .overlay {
        avatarPreviewOverlay(for: presentation)
      }
      .task(id: request) {
        isPreviewingAvatar = false
        await loader.load(request)
      }
    }

    @ViewBuilder
    private func avatarPreviewOverlay(for presentation: ParticipantAvatarLoader.Presentation) -> some View {
      if supportsPreview, case let .image(_, data) = presentation,
         let previewItem = ParticipantAvatarImage.previewItem(for: data) {
        Button {
          isPreviewingAvatar = true
        } label: {
          Color.clear
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(DiaryStringKey.Participant.viewAvatar))
        .background {
          HPreviewButton(item: previewItem, shouldPreview: $isPreviewingAvatar)
            .id(data)
            .accessibilityHidden(true)
        }
      }
    }
  }
#endif
