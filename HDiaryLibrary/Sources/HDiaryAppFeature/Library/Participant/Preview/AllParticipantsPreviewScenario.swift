#if DEBUG && os(iOS)
  enum AllParticipantsPreviewScenario: String, CaseIterable {
    case populated, empty, dark, accessibility
    case avatarVariants = "avatar-variants"
    case singleParticipant = "single-participant"
  }
#endif
