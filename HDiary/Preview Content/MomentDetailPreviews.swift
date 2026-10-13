#if DEBUG && os(iOS)
  @testable import HDiaryAppFeature
  import SwiftUI

  // Use the app target's real localization catalog and AccentColor, just like participant previews.
  #Preview("乐事详情 · 完整内容", traits: .fixedLayout(width: 402, height: 874)) {
    MomentDetailPreview(fixture: .make(.populated))
  }

  #Preview("乐事详情 · 精简内容", traits: .fixedLayout(width: 402, height: 874)) {
    MomentDetailPreview(fixture: .make(.minimal))
  }

  #Preview("乐事详情 · 长标题与长正文", traits: .fixedLayout(width: 402, height: 874)) {
    MomentDetailPreview(fixture: .make(.longContent))
  }

  #Preview("乐事详情 · 深色模式", traits: .fixedLayout(width: 402, height: 874)) {
    MomentDetailPreview(fixture: .make(.dark))
  }

  #Preview("乐事详情 · 辅助功能字号", traits: .fixedLayout(width: 402, height: 874)) {
    MomentDetailPreview(fixture: .make(.accessibility))
  }

  #Preview("乐事详情 · 窄宽度大字号", traits: .fixedLayout(width: 320, height: 874)) {
    MomentDetailPreview(fixture: .make(.compactAccessibility))
  }
#endif
