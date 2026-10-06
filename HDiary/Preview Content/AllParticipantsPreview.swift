#if DEBUG && os(iOS)
  @testable import HDiaryAppFeature
  import SwiftUI

  // Host previews in the app target so the real localization catalog is available.
  #Preview("正式页面 · A", traits: .fixedLayout(width: 402, height: 874)) {
    AllParticipantsPreview(fixture: .make(.populated))
  }

  #Preview("正式页面 · 空列表", traits: .fixedLayout(width: 402, height: 874)) {
    AllParticipantsPreview(fixture: .make(.empty))
  }

  #Preview("正式页面 · 深色", traits: .fixedLayout(width: 402, height: 874)) {
    AllParticipantsPreview(fixture: .make(.dark))
  }

  #Preview("正式页面 · 长昵称与大字号", traits: .fixedLayout(width: 402, height: 874)) {
    AllParticipantsPreview(fixture: .make(.accessibility))
  }

  #Preview("正式页面 · 头像与姓名回退", traits: .fixedLayout(width: 402, height: 874)) {
    AllParticipantsPreview(fixture: .make(.avatarVariants))
  }

  #Preview("正式页面 · 窄屏", traits: .fixedLayout(width: 320, height: 640)) {
    AllParticipantsPreview(fixture: .make(.populated))
  }

  #Preview("正式页面 · 单个参与者", traits: .fixedLayout(width: 402, height: 874)) {
    AllParticipantsPreview(fixture: .make(.singleParticipant))
  }

  #Preview("正式页面 · 蓝色主题", traits: .fixedLayout(width: 402, height: 874)) {
    AllParticipantsPreview(fixture: .make(.populated), tintColor: .blue)
  }

  #Preview("参与者详情 · 图片头像", traits: .fixedLayout(width: 402, height: 874)) {
    ParticipantDetailPreview(fixture: .make(.populated))
  }

  #Preview("参与者详情 · 透明头像回退", traits: .fixedLayout(width: 402, height: 874)) {
    ParticipantDetailPreview(fixture: .make(.transparentAvatar))
  }

  #Preview("参与者详情 · 无备注和乐事", traits: .fixedLayout(width: 402, height: 874)) {
    ParticipantDetailPreview(fixture: .make(.empty))
  }

  #Preview("参与者详情 · 深色", traits: .fixedLayout(width: 402, height: 874)) {
    ParticipantDetailPreview(fixture: .make(.dark))
  }

  #Preview("参与者详情 · 辅助功能字号", traits: .fixedLayout(width: 402, height: 874)) {
    ParticipantDetailPreview(fixture: .make(.accessibility))
  }
#endif
