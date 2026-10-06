#if os(iOS)
  import Foundation
  import HDiaryModel

  extension Participant {
    var displayName: String {
      let trimmedNickname = nickName.trimmingCharacters(in: .whitespacesAndNewlines)
      return trimmedNickname.isEmpty ? name.trimmingCharacters(in: .whitespacesAndNewlines) : trimmedNickname
    }
  }
#endif
