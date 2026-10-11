#if DEBUG && os(iOS)
  import HDiaryConstants
  import HDiaryModel
  import HDiarySearch
  import SwiftData
  import SwiftUI
  import UIKit

  /// Opt-in, offline marketing data. The Release build contains no screenshot mode.
  @MainActor
  final class AppStoreScreenshotFixture {
    static let active: AppStoreScreenshotFixture? = {
      guard UserDefaults.standard.bool(forKey: "HDiaryStoreScreenshots") else { return nil }
      do { return try AppStoreScreenshotFixture() }
      catch { fatalError("Cannot create App Store screenshot fixture: \(error)") }
    }()

    let container: ModelContainer
    let search: SearchViewModel
    let cloudState = MomentCloudStateManager(shouldSync: false)
    let navigation = NavigationStore()
    let page = UserDefaults.standard.string(forKey: "HDiaryScreenshotPage") ?? "moments"
    let locale = Locale(identifier: UserDefaults.standard.string(forKey: "HDiaryScreenshotLocale") ?? "zh-Hans")
    let referenceDate = Calendar.current.startOfDay(for: .now).addingTimeInterval(12 * 3600)

    private init() throws {
      container = try ModelContainer(
        for: Moment.self, Tag.self, Participant.self, MediaItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
      )
      search = SearchViewModel(modelContainer: container)
      let context = container.mainContext
      context.autosaveEnabled = false
      let chinese = locale.identifier.hasPrefix("zh")
      let tags = (chinese ? ["生活", "自然", "朋友", "美食", "阅读", "旅行"]
        : ["Everyday", "Nature", "Friends", "Food", "Reading", "Travel"]).map { Tag(text: $0) }
      tags.forEach { context.insert($0) }
      let people = (chinese ? ["小雨", "阿树", "妈妈", "爸爸", "安安", "小满", "悠悠", "小夏", "星星", "圆圆", "小禾", "林林"]
        : ["Lily", "Alex", "Mom", "Dad", "Anna", "Max", "Chloe", "Summer", "Stella", "Oliver", "Leo", "Lin"])
        .map { Participant.create(name: $0, nickName: $0) }
      people.forEach { context.insert($0) }
      let titles = chinese ? [
        "把秋天的阳光画下来", "和朋友慢慢喝一杯咖啡", "读完一本喜欢的书", "一起做了热乎乎的晚饭",
        "傍晚的风刚刚好", "周末去逛了小小的花市", "跑完步，心情也放晴了", "收到了远方朋友的明信片",
        "试着烤了第一盘饼干", "在公园遇见一只小猫", "和家人分享今天的好消息", "发现一家喜欢的书店",
      ] : [
        "Autumn in my sketchbook", "A slow coffee with friends", "Finished a wonderful book", "A warm, homemade dinner",
        "The perfect evening breeze", "Flowers at the weekend market", "A good run, a brighter mood", "A postcard from a faraway friend",
        "My first batch of cookies", "Met a little cat in the park", "Sharing good news with family", "Found a lovely little bookshop",
      ]
      let tagIndices = [[1, 2], [2, 3], [4], [3], [1], [0, 1], [0], [2], [3], [1], [0], [4]]
      var moments: [Moment] = []
      for (index, title) in titles.enumerated() {
        let day = index / 2
        let date = Calendar.current.date(byAdding: .day, value: -day, to: referenceDate)!
          .addingTimeInterval(Double(index % 2) * -7200)
        let moment = Moment.create(timestamp: date)
        context.insert(moment)
        moment.updateTitle(title)
        moment.updateContent(chinese
          ? "和小雨、阿树沿着湖边散步，把眼前的风景画了下来。阳光落在水面上，风轻轻吹过。\n\n原来，值得记住的快乐，就藏在这些平常的时刻里。"
          : "A walk by the lake with Lily and Alex, and a little sketch to remember it. Sunlight on the water, a soft breeze in the trees.\n\nThe happiest memories are often the simplest ones.")
        moment.updateTags(tagIndices[index].map { tags[$0] })
        moment.updateParticipants(index < 2 ? Array(people.prefix(2)) : [people[index % people.count]])
        moment.updateRating([5, 4, 5, 4, 3, 5, 4, 5, 3, 4, 5, 4][index])
        if index == 0 {
          let data = Self.landscape()
          context.insert(MediaItem(data: data, moment: moment, mediaType: .image, pathExtension: "png",
                                   thumbnailData150px: data, thumbnailData500px: data, thumbnailData1000px: data))
        }
        moments.append(moment)
      }
      try context.save()

      let route = HDiaryRoute.shared
      route.selectedTab = ["moments", "detail"].contains(page) ? .content : .library
      route.libraryNavigationStore.path = []
      if page == "detail" { navigation.path = [.moment(moments[0], editEnabled: true)] }
      if page == "participants" { route.libraryNavigationStore.path = [.libraryEntry(entry: .participant)] }
      if page == "tags" { route.libraryNavigationStore.path = [.libraryEntry(entry: .tag)] }
      if page == "chart" { route.libraryNavigationStore.path = [.libraryEntry(entry: .chart), .chartEntry(.rating)] }
    }

    private static func landscape() -> Data {
      let format = UIGraphicsImageRendererFormat()
      format.scale = 1
      format.opaque = true
      return UIGraphicsImageRenderer(size: CGSize(width: 1200, height: 800), format: format).pngData { renderer in
        let cg = renderer.cgContext
        UIColor(red: 0.96, green: 0.87, blue: 0.70, alpha: 1).setFill()
        cg.fill(CGRect(x: 0, y: 0, width: 1200, height: 800))
        UIColor(red: 0.98, green: 0.63, blue: 0.28, alpha: 1).setFill()
        cg.fillEllipse(in: CGRect(x: 820, y: 95, width: 170, height: 170))
        UIColor(red: 0.60, green: 0.70, blue: 0.61, alpha: 1).setFill()
        let hills = UIBezierPath()
        hills.move(to: CGPoint(x: 0, y: 420))
        hills.addCurve(to: CGPoint(x: 650, y: 400), controlPoint1: CGPoint(x: 280, y: 160), controlPoint2: CGPoint(x: 360, y: 200))
        hills.addCurve(to: CGPoint(x: 1200, y: 360), controlPoint1: CGPoint(x: 940, y: 240), controlPoint2: CGPoint(x: 1080, y: 300))
        hills.addLine(to: CGPoint(x: 1200, y: 800))
        hills.addLine(to: CGPoint(x: 0, y: 800))
        hills.close()
        hills.fill()
        UIColor(red: 0.43, green: 0.62, blue: 0.62, alpha: 1).setFill()
        cg.fill(CGRect(x: 0, y: 480, width: 1200, height: 320))
        UIColor(red: 0.94, green: 0.82, blue: 0.58, alpha: 1).setStroke()
        cg.setLineWidth(5)
        for row in 0..<8 {
          let y = 520 + row * 28
          cg.move(to: CGPoint(x: 720 - row * 18, y: y))
          cg.addLine(to: CGPoint(x: 940 + row * 15, y: y))
        }
        cg.strokePath()
      }
    }
  }

  struct AppStoreScreenshotView: View {
    let fixture: AppStoreScreenshotFixture

    var body: some View {
      @Bindable var navigation = fixture.navigation
      @Bindable var route = HDiaryRoute.shared
      HDiaryTabShell(
        selection: $route.selectedTab,
        searchViewModel: .constant(fixture.search),
        supportsSearch: true,
        content: NavigationStack(path: $navigation.path) {
          MomentListScreen(referenceDate: fixture.referenceDate, initiallyExpanded: true)
            .navigationTitle(Text(DiaryStringKey.happyListNavigationTitle))
        }.environment(navigation),
        library: LibraryView(isSelected: .constant(true)),
        settings: Color.clear
      )
      .modelContainer(fixture.container)
      .environment(fixture.search)
      .environment(fixture.cloudState)
      .environment(route)
      .environment(UserPreferences.shared)
      .environment(\.locale, fixture.locale)
      .environment(\.dynamicTypeSize, .large)
      .preferredColorScheme(.light)
      .tint(.orange)
      .transaction { $0.animation = nil }
    }
  }
#endif
