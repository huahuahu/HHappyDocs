#if os(iOS)
  import HDiaryModel
  import QuickLook
  import SFSafeSymbols
  import SwiftUI

  struct ParticipantAvatarView: View {
    let participant: Participant
    let size: CGFloat
    var supportsPreview = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale
    @State private var loader: ParticipantAvatarLoader
    @State private var preview: ParticipantAvatarPreview

    init(
      participant: Participant, size: CGFloat, supportsPreview: Bool = false,
      loader: ParticipantAvatarLoader = ParticipantAvatarLoader(),
      preview: ParticipantAvatarPreview = ParticipantAvatarPreview()
    ) {
      self.participant = participant
      self.size = size
      self.supportsPreview = supportsPreview
      self._loader = State(initialValue: loader)
      self._preview = State(initialValue: preview)
    }

    var body: some View {
      @Bindable var preview = preview
      let request = ParticipantAvatarLoader.Request(
        participantID: participant.uuid,
        data: participant.avatar,
        maxPixelSize: max(1, Int((size * displayScale).rounded(.up)))
      )
      let presentation = loader.presentation(for: request)
      let source = ParticipantAvatarPreview.Source(
        participantID: participant.uuid, data: participant.avatar, isEnabled: supportsPreview
      )
      let previewData = supportsPreview ? presentation.previewData(matching: request.data) : nil
      avatarControl(presentation: presentation, previewData: previewData)
        .quickLookPreview($preview.previewURL)
        .alert(Text(DiaryStringKey.Participant.avatarPreviewFailed), isPresented: $preview.showsError) {
          if let previewData {
            Button(DiaryStringKey.Participant.retryAvatarPreview) {
              preview.begin(data: previewData)
            }
          }
          Button(DiaryStringKey.Common.cancel, role: .cancel) {}
        } message: {
          Text(DiaryStringKey.Participant.avatarPreviewFailureMessage)
        }
        .onChange(of: source) { preview.reset() }
        .task(id: preview.request?.id) {
          await preview.prepare()
        }
        .task(id: request) {
          await loader.load(request)
        }
    }

    @ViewBuilder
    private func avatarControl(
      presentation: ParticipantAvatarLoader.Presentation, previewData: Data?
    ) -> some View {
      if let previewData {
        Button {
          preview.begin(data: previewData)
        } label: {
          avatarImage(for: presentation)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(preview.request != nil)
        .accessibilityLabel(Text(DiaryStringKey.Participant.viewAvatar))
      }
      else {
        avatarImage(for: presentation)
          .accessibilityHidden(true)
      }
    }

    private func avatarImage(for presentation: ParticipantAvatarLoader.Presentation) -> some View {
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
    }
  }
#endif
