#if DEBUG
  @testable import HDiaryWidgetFeature
  import Foundation
  import HDiaryWidgetIntents
  import UIKit

  @MainActor
  enum MomentWidgetPreviewFixtures {
    static let date = Date(timeIntervalSince1970: 1_791_417_600)
    static let participant = ParticipantEntity(
      id: UUID(uuidString: "00000000-0000-0000-0000-000000000001").unsafelyUnwrapped,
      name: "花花虎",
      avatar: ParticipantEntity.defaultAvatar
    )
    static let titles = ["和朋友一起爬山，看到了山顶的日出", "一家人围坐在一起，慢慢吃一顿晚饭", "午后咖啡小聚", "散步时遇到一只亲人的小猫", "读完了一本喜欢的书"]
    static let moments = titles.enumerated().map { index, title in
      MomentWidgetSummary.Moment(
        timeStamp: date.addingTimeInterval(-Double(index) * 86_400),
        title: title,
        id: UUID(uuidString: "00000000-0000-0000-0001-00000000000\(index)").unsafelyUnwrapped
      )
    }

    static let populated = MomentEntry(date: date, summary: .init(participant: participant, moments: moments))
    static let longContent = MomentEntry(date: date, summary: .init(
      participant: ParticipantEntity(id: participant.id, name: "一起去看山川湖海的好朋友，名字也可以很长很长", avatar: participant.avatar),
      moments: moments.map { .init(timeStamp: $0.timeStamp, title: String(repeating: $0.title + "，", count: 8), id: $0.id) }
    ))
    static let single = MomentEntry(date: date, summary: .init(participant: participant, moments: Array(moments.prefix(1))))
    static let empty = MomentEntry(date: date, summary: .init(participant: participant, moments: []))
    static let allParticipants = MomentEntry(date: date, summary: .init(participant: .nonEntity, moments: moments))

    /// Deterministic raster avatar exercises the photo rendering path without user photos.
    static let photo = MomentEntry(date: date, summary: .init(
      participant: ParticipantEntity(id: participant.id, name: participant.name, avatar: {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 72, height: 72), format: format).image { context in
          UIColor(red: 1, green: 0.45, blue: 0.05, alpha: 1).setFill()
          context.fill(CGRect(x: 0, y: 0, width: 72, height: 72))
          UIColor(red: 0.05, green: 0.35, blue: 0.85, alpha: 1).setFill()
          context.fill(CGRect(x: 36, y: 0, width: 36, height: 72))
          UIColor.white.setFill()
          context.cgContext.fillEllipse(in: CGRect(x: 18, y: 18, width: 36, height: 36))
        }
      }()),
      moments: moments
    ))
  }
#endif
