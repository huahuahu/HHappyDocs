#if os(iOS)
  import HDiaryConstants
  import HDiaryModel
  import HUIComponent
  import PhotosUI
  import SwiftUI

  struct AvatarSelectionView: View {
    let participant: Participant
    @State private var item: PhotosPickerItem?
    @State private var editor: AvatarEditingSession
    @ScaledMetric private var size = Design.Avatar.size

    init(participant: Participant, editor: AvatarEditingSession = AvatarEditingSession()) {
      self.participant = participant
      self._editor = State(initialValue: editor)
    }

    var body: some View {
      @Bindable var editor = editor
      VStack(spacing: 12) {
        PhotosPicker(selection: $item, matching: .images, preferredItemEncoding: .current) {
          VStack(spacing: 12) {
            ParticipantAvatarView(participant: participant, size: min(size, 160))
            Label {
              Text(DiaryStringKey.Participant.changeAvatar)
            } icon: {
              Image(systemName: "photo")
            }
          }
          .frame(maxWidth: .infinity)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.tint)
        .disabled(editor.request != nil)
        .accessibilityLabel(Text(DiaryStringKey.Participant.changeAvatar))
        .accessibilityHint(Text(DiaryStringKey.Participant.avatarEditingHint))
        .accessibilityIdentifier("avatar.choose")

        if editor.request != nil {
          ProgressView {
            Text(DiaryStringKey.Participant.loadingAvatar)
          }
          Button(DiaryStringKey.Common.cancel, role: .cancel) { editor.reset() }
            .accessibilityIdentifier("avatar.cancelLoading")
        }
      }
      .onChange(of: item) { _, selectedItem in
        guard let selectedItem else { return }
        // Reset immediately so selecting the same photo again is a new selection.
        item = nil
        editor.begin(selectedItem)
      }
      .task(id: editor.request?.id) {
        await editor.load()
      }
      .fullScreenCover(item: $editor.crop, onDismiss: editor.reset) { crop in
        HImageCropper(originalImage: crop.image, imageSize: CGSize(width: 320, height: 320)) { image in
          try editor.commit(image, to: participant)
        }
      }
      .alert(Text(DiaryStringKey.Participant.avatarLoadFailed), isPresented: $editor.showsLoadError) {
        Button(DiaryStringKey.Participant.retryAvatarPreview) { editor.retry() }
        Button(DiaryStringKey.Common.cancel, role: .cancel) { editor.reset() }
      } message: {
        Text(DiaryStringKey.Participant.avatarLoadFailureMessage)
      }
    }
  }
#endif
