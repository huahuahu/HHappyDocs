#if DEBUG && os(iOS)
  enum ParticipantDetailPreviewScenario: String, CaseIterable {
    case populated, empty, dark, accessibility
    case transparentAvatar = "transparent-avatar"
  }
#endif
