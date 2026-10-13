#if DEBUG && os(iOS)
  import Foundation
  import HDiaryModel
  import HDiarySearch
  import SwiftData
  import UIKit

  /// Each preview owns saved, fictional data; visiting or editing only changes this memory store.
  @MainActor
  struct MomentDetailPreviewFixture {
    let scenario: MomentDetailPreviewScenario
    let container: ModelContainer
    let searchViewModel: SearchViewModel
    let cloudState = MomentCloudStateManager(shouldSync: false)
    let moment: Moment

    static var calendar: Calendar {
      var calendar = Calendar(identifier: .gregorian)
      calendar.locale = Locale(identifier: "zh_CN")
      guard let timeZone = TimeZone(secondsFromGMT: 8 * 60 * 60) else {
        preconditionFailure("Invalid moment detail preview time zone")
      }
      calendar.timeZone = timeZone
      return calendar
    }

    // 2026-10-03 17:30 in UTC+8.
    static let referenceDate = Date(timeIntervalSince1970: 1_791_019_800)

    static func make(_ scenario: MomentDetailPreviewScenario) -> Self {
      do {
        return try Self(scenario: scenario)
      }
      catch {
        fatalError("Could not create moment detail preview: \(error)")
      }
    }

    init(scenario: MomentDetailPreviewScenario) throws {
      self.scenario = scenario
      container = try ModelContainer(
        for: Moment.self, Tag.self, Participant.self, MediaItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
      )
      let context = container.mainContext
      context.autosaveEnabled = false
      searchViewModel = SearchViewModel(modelContainer: container)
      moment = Moment.create(timestamp: Self.referenceDate)
      context.insert(moment)
      moment.lastVisitDate = Self.referenceDate

      if scenario == .minimal {
        moment.updateTitle("今天的小确幸")
        moment.updateContent("回家路上闻到了桂花香。")
        // Keep the default unset rating and empty participant, tag and media relationships.
      }
      else {
        moment.updateTitle(scenario == .longContent
          ? "和朋友沿着湖边慢慢散步，等到夕阳把天空染成橙色，再把这段值得珍藏的周末时光认真记下来 🌅"
          : "和朋友在湖边看日落 🌅")
        moment.updateContent(scenario == .longContent ? Self.longContent : Self.content)
        moment.updateRating(4)

        let participants = [
          Participant.create(name: "陈小雨", nickName: "小雨"),
          Participant.create(name: "林知远", nickName: "阿远"),
        ]
        participants.forEach { context.insert($0) }
        moment.updateParticipants(participants)

        let tags = [Tag(text: "朋友"), Tag(text: "自然"), Tag(text: "周末散步")]
        for tag in tags {
          tag.creationDate = Self.referenceDate
          context.insert(tag)
        }
        moment.updateTags(tags)

        let imageData = Self.landscapePNG()
        context.insert(MediaItem(
          data: imageData, moment: moment, mediaType: .image, pathExtension: "png",
          thumbnailData150px: imageData, thumbnailData500px: imageData, thumbnailData1000px: imageData
        ))
      }
      try context.save()
    }

    private static let content = """
    下午和小雨、阿远一起沿湖散步，聊了最近读的书。

    走到长椅旁时，夕阳刚好落在水面上。我们停下来拍了一张照片，把这一刻的轻松与开心留住。

    回家路上，我们约好下次再来这里，慢慢走一段新的小路。
    """

    private static let longContent = """
    今天没有安排赶时间的行程。吃过午饭，我们从熟悉的街角出发，绕过花店和书店，再沿着树荫走到湖边。风吹过的时候，脚下的落叶轻轻翻了个面，连平时匆匆走过的小路也显得有些不同。

    小雨说起最近读到的一段故事，阿远分享了第一次学做面包的经历。我们边走边笑，偶尔停下来看看水里的倒影。没有谁急着得出结论，能把这些零碎的小事讲给愿意听的人，就已经很开心了。

    走到桥边时，阳光从云层的缝隙里照下来。远处有孩子在放风筝，近处有人坐着画画。我们挑了一张空长椅坐下，把带来的水果分着吃，发现最甜的那一块总会被递给旁边的人。

    傍晚的颜色一点点变暖，湖面从浅蓝变成金色。我试着拍下眼前的景色，也提醒自己放下手机认真看一会儿。照片能留住光线，却留不住当时的风和身边的笑声，所以想把这些感受一起写下来。

    回程经过一家小店，我们各选了一张明信片，约好下次去另一条没走过的小路。A small, lovely afternoon — 不需要特别盛大的理由，也可以成为值得记住的一天。

    记到这里，仍然能想起夕阳落在水面上的样子。希望以后的自己翻到这篇乐事时，还能记得今天的轻松、朋友的陪伴，以及慢下来才发现的美好。下方的本地示例图片，是这段长正文之后的小小句点。
    """

    /// Fixed pixels and colors, generated locally without photos, network access or symbol assets.
    private static func landscapePNG() -> Data {
      let format = UIGraphicsImageRendererFormat()
      format.scale = 1
      format.opaque = true
      return UIGraphicsImageRenderer(size: CGSize(width: 600, height: 400), format: format).pngData { context in
        UIColor(red: 0.96, green: 0.85, blue: 0.73, alpha: 1).setFill()
        context.fill(CGRect(x: 0, y: 0, width: 600, height: 400))
        UIColor(red: 1, green: 0.64, blue: 0.28, alpha: 1).setFill()
        context.cgContext.fillEllipse(in: CGRect(x: 420, y: 55, width: 90, height: 90))
        UIColor(red: 0.34, green: 0.58, blue: 0.59, alpha: 1).setFill()
        context.fill(CGRect(x: 0, y: 220, width: 600, height: 180))
        UIColor(red: 0.24, green: 0.43, blue: 0.36, alpha: 1).setFill()
        let shore = UIBezierPath()
        shore.move(to: CGPoint(x: 0, y: 180))
        shore.addLine(to: CGPoint(x: 180, y: 125))
        shore.addLine(to: CGPoint(x: 390, y: 245))
        shore.addLine(to: CGPoint(x: 0, y: 280))
        shore.close()
        shore.fill()
      }
    }
  }
#endif
