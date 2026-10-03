#if DEBUG && os(iOS)

  import HDiaryModel
  import HDiarySearch
  import SwiftData
  import SwiftUI
  import UIKit

  enum MomentListPreviewScenario: String, CaseIterable {
    case grouped
    case expanded
    case empty

    var purpose: String {
      switch self {
      case .grouped:
        "固定日期分组及数量；已删除的日记不出现。"
      case .expanded:
        "展开今天和昨天的内容；覆盖长标题截断、标签、缩略图和纯文字行。"
      case .empty:
        "记录原有空列表的页面标题和空白布局。"
      }
    }
  }

  /// Preview 和截图测试共用构造方法，每次创建独立的内存数据库和离线云状态。
  @MainActor
  struct MomentListPreviewFixture {
    let scenario: MomentListPreviewScenario
    let container: ModelContainer
    let searchViewModel: SearchViewModel
    let cloudState = MomentCloudStateManager(shouldSync: false)

    static var calendar: Calendar {
      var calendar = Calendar(identifier: .gregorian)
      calendar.locale = Locale(identifier: "zh_CN")
      calendar.timeZone = TimeZone(secondsFromGMT: 8 * 60 * 60)!
      return calendar
    }

    static let referenceDate = date(year: 2026, month: 10, day: 3, hour: 12)

    init(scenario: MomentListPreviewScenario) throws {
      self.scenario = scenario
      let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
      container = try ModelContainer(
        for: Moment.self, Tag.self, Participant.self, MediaItem.self,
        configurations: configuration
      )
      searchViewModel = SearchViewModel(modelContainer: container)
      container.mainContext.autosaveEnabled = false
      guard scenario != .empty else { return }

      let context = container.mainContext
      let nature = Tag(text: "自然")
      let life = Tag(text: "生活")
      let reading = Tag(text: "阅读")
      [nature, life, reading].forEach { context.insert($0) }

      func insert(_ title: String, at timestamp: Date, tags: [Tag] = [], thumbnail: Bool = false) -> Moment {
        let moment = Moment.create(timestamp: timestamp)
        moment.updateTitle(title)
        moment.updateContent("截图测试专用的虚构记录。")
        moment.updateTags(tags)
        moment.updateRating(4)
        moment.lastVisitDate = Self.referenceDate
        context.insert(moment)
        if thumbnail {
          let data = Self.thumbnailPNG()
          let media = MediaItem(
            data: data, moment: moment, mediaType: .image, pathExtension: "png",
            thumbnailData150px: data, thumbnailData500px: data, thumbnailData1000px: data
          )
          context.insert(media)
        }
        return moment
      }

      _ = insert("清晨散步，遇见一片温柔的阳光", at: Self.date(day: 3, hour: 10), tags: [nature, life], thumbnail: true)
      _ = insert("读完一本惦记了很久的书，把喜欢的句子认真抄下来，留给以后的自己", at: Self.date(day: 3, hour: 9), tags: [reading])
      _ = insert("和朋友喝了一杯咖啡 ☕️", at: Self.date(day: 2, hour: 16), tags: [life])
      _ = insert("今天也有值得记住的小事", at: Self.date(day: 2, hour: 8))
      _ = insert("九月最后一次傍晚散步", at: Self.date(month: 9, day: 29, hour: 18), tags: [nature])
      _ = insert("整理夏天的照片", at: Self.date(month: 8, day: 12, hour: 14))
      _ = insert("去年冬天的一次重逢", at: Self.date(year: 2025, month: 12, day: 20, hour: 14))
      let deleted = insert("这条已删除的日记不应出现", at: Self.date(day: 3, hour: 11))
      deleted.markAsDelete()
      try context.save()
    }

    private static func date(year: Int = 2026, month: Int = 10, day: Int, hour: Int) -> Date {
      calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    /// 固定像素的本地图片，不依赖网络、相册或 SF Symbols 版本。
    private static func thumbnailPNG() -> Data {
      let format = UIGraphicsImageRendererFormat()
      format.scale = 1
      format.opaque = true
      return UIGraphicsImageRenderer(size: CGSize(width: 80, height: 80), format: format).pngData { context in
        UIColor(red: 0.85, green: 0.93, blue: 0.95, alpha: 1).setFill()
        context.fill(CGRect(x: 0, y: 0, width: 80, height: 80))
        UIColor(red: 0.99, green: 0.76, blue: 0.35, alpha: 1).setFill()
        context.cgContext.fillEllipse(in: CGRect(x: 48, y: 10, width: 20, height: 20))
        UIColor(red: 0.25, green: 0.53, blue: 0.43, alpha: 1).setFill()
        let hill = UIBezierPath()
        hill.move(to: CGPoint(x: 0, y: 60))
        hill.addLine(to: CGPoint(x: 30, y: 28))
        hill.addLine(to: CGPoint(x: 80, y: 65))
        hill.addLine(to: CGPoint(x: 80, y: 80))
        hill.addLine(to: CGPoint(x: 0, y: 80))
        hill.close()
        hill.fill()
      }
    }
  }

  struct MomentListPreview: View {
    let fixture: MomentListPreviewFixture

    var body: some View {
      HDiaryTabShell(
        selection: .constant(.content),
        searchViewModel: .constant(fixture.searchViewModel),
        supportsSearch: fixture.scenario != .empty,
        content: NavigationStack {
          MomentListScreen(
            referenceDate: MomentListPreviewFixture.referenceDate,
            initiallyExpanded: fixture.scenario == .expanded
          )
          .navigationTitle(Text(DiaryStringKey.happyListNavigationTitle))
        },
        library: Color.clear,
        settings: Color.clear
      )
      .modelContainer(fixture.container)
      .environment(fixture.cloudState)
      .environment(\.calendar, MomentListPreviewFixture.calendar)
      .environment(\.timeZone, MomentListPreviewFixture.calendar.timeZone)
      .environment(\.locale, Locale(identifier: "zh_CN"))
      .environment(\.dynamicTypeSize, .large)
      .environment(\.colorScheme, .light)
      .scrollIndicators(.hidden)
      .transaction { $0.animation = nil }
    }
  }

  #Preview("列表 · 日期分组") {
    MomentListPreview(fixture: try! MomentListPreviewFixture(scenario: .grouped))
  }

  #Preview("列表 · 展开内容") {
    MomentListPreview(fixture: try! MomentListPreviewFixture(scenario: .expanded))
  }

  #Preview("列表 · 空数据") {
    MomentListPreview(fixture: try! MomentListPreviewFixture(scenario: .empty))
  }

#endif
