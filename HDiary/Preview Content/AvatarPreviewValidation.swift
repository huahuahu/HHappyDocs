#if DEBUG && os(iOS)
  @testable import HDiaryAppFeature
  import SwiftUI

  #Preview("头像预览 · 交互与失败重试") {
    ParticipantAvatarPreviewValidationView()
  }
#endif
