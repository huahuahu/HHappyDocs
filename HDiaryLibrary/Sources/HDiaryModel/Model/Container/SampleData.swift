//
//  File.swift
//
//
//  Created by tigerguo on 2023/8/26.
//
#if os(iOS)

  import Foundation
  import HDiaryConstants
  import HMedia
  import SwiftData
  import SwiftUI
  import UIKit

  extension HDiaryContainer {
    @MainActor
    public static let inMemoryPreviewContainer: ModelContainer = {
      let schema = Schema.hDiaryScheme
      // https://www.hackingwithswift.com/forums/swiftui/swiftdata-isstoredinmemoryonly-true-not-working-on-macos-icloud/25573
      let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)

      let container: ModelContainer

      do {
        container = try ModelContainer(for: schema, configurations: [configuration])
      }
      catch {
        fatalError("Failed to create inMemory container")
      }
      Task {
        do {
          try await SampleDataHandler.inMemoryDataHandler.insertSampleData()
        }
        catch {
          Log.data.error("Failed to insert sample data to inMemory container: \(error)")
        }
      }
      return container
    }()

    @MainActor
    public static let inMemoryEmptyPreviewContainer: ModelContainer = {
      let schema = Schema.hDiaryScheme
      let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)

      let container: ModelContainer

      do {
        container = try ModelContainer(for: schema, configurations: [configuration])
      }
      catch {
        fatalError("Failed to create inMemory container")
      }
      return container
    }()
  }

  // Seems ModelActor would bound to the main thread, which is not what we want.
//  @ModelActor
  public actor SampleDataHandler {
    // https://developer.apple.com/forums/thread/757521
    // When an @ModelActor is created and later released (for example dropped at the end of a function scope), the model instances fetched by its associated model context can't be meaningfully used anymore.
    @MainActor public static let inMemoryDataHandler = SampleDataHandler(modelContainer: HDiaryContainer.inMemoryPreviewContainer)
    @MainActor public static let localDataHandler = SampleDataHandler(modelContainer: HDiaryContainer.localContainer)
    @MainActor public static let cloudDataHandler = SampleDataHandler(modelContainer: HDiaryContainer.iCloudContainer)

    let container: ModelContainer

    init(modelContainer: ModelContainer) {
      self.container = modelContainer
    }

    public func insertMoments(count: Int, dateRange: ClosedRange<Date>) throws {
      Log.data.debug("insertMoments \(count) start")
      Log.data.debug("insertMoments current thread: \(Thread.current), is main thread: \(Thread.isMainThread)")
      let modelContext = ModelContext(container)
      var availableTags: [Tag] = try modelContext.fetch(FetchDescriptor())
      if availableTags.isEmpty {
        availableTags = Tag.getSampleTags()
        availableTags.forEach { modelContext.insert($0) }
      }
      var availableParticipants: [Participant] = try modelContext.fetch(FetchDescriptor())
      if availableParticipants.isEmpty {
        availableParticipants = Participant.getSampleParticipants()
        availableParticipants.forEach { modelContext.insert($0) }
      }

      let sampleMoments = Moment.getSampleMoments(count: count, dateRange: dateRange)
      for moment in sampleMoments {
        moment.updateTags(availableTags.getRandomElements)
        moment.updateParticipants(availableParticipants.getRandomElements)
        (0 ... 5).randomElement().map { moment.updateRating($0) }
        if let titleAndDescription = TitleAndDescription.allDemos.randomElement() {
          moment.updateTitle(titleAndDescription.title)
          moment.updateContent(titleAndDescription.description)
          moment.updateMedias(TestImage.symbols.getRandomElements.compactMap { MediaItem.from(systemName: $0) })
        }
      }
      sampleMoments.forEach { modelContext.insert($0) }
      try modelContext.save()
      Log.data.debug("insertMoments \(count) end")
    }

    public func clearAllData() throws {
      let modelContext = ModelContext(container)
      Log.data.debug("clearAllData start")
      Log.data.debug("clearAllData current thread: \(Thread.current), is main thread: \(Thread.isMainThread)")
      try modelContext.delete(model: Moment.self)
      try modelContext.delete(model: Tag.self)
      try modelContext.delete(model: Participant.self)
      try modelContext.delete(model: MediaItem.self)
      try modelContext.delete(model: HappyImage.self)
      try modelContext.save()
      Log.data.debug("delete all data")
//
    }

    public func insertSampleData() throws {
      Log.data.debug("insertSampleData start")
      let modelContext = ModelContext(container)
      Log.data.debug("insertSampleData current thread: \(Thread.current), is main thread: \(Thread.isMainThread)")
      let sampleTags = Tag.getSampleTags()
      for tag in sampleTags {
        modelContext.insert(tag)
      }

      let sampleParticipants = Participant.getSampleParticipants()
      for participant in sampleParticipants {
        ParticipantProperties.allDemos.randomElement().map {
          participant.note = $0.note
          participant.avatar = UIImage(systemName: TestImage.symbols.randomElement().unsafelyUnwrapped)?.heicData()
        }
        modelContext.insert(participant)
      }

      let sampleMoments = Moment.getSampleMoments(count: 20)
      for moment in sampleMoments {
        moment.updateTags(sampleTags.getRandomElements)
        moment.updateParticipants(sampleParticipants.getRandomElements)
        (0 ... 5).randomElement().map { moment.updateRating($0) }
        if let titleAndDescription = TitleAndDescription.allDemos.randomElement() {
          moment.updateTitle(titleAndDescription.title)
          moment.updateContent(titleAndDescription.description)
          moment.updateMedias(TestImage.symbols.getRandomElements.compactMap { MediaItem.from(systemName: $0) })
        }
      }

      sampleMoments.forEach { modelContext.insert($0) }
      try modelContext.save()

      Log.data.debug("insertSampleData end")
    }

    deinit {
      assertionFailure("SampleDataHandler should not deinit")
    }
  }

  public struct SampleDataModifier: PreviewModifier {
    public init() {}
    public static func makeSharedContext() throws -> ModelContainer {
      let container = HDiaryContainer.inMemoryPreviewContainer
      return container
    }

    public func body(content: Content, context: ModelContainer) -> some View {
      content.modelContainer(context)
    }
  }

  public extension Tag {
    static func getSampleTags() -> [Tag] {
      return [
        Tag(text: "自然", comments: "自然风光很美丽"),
        Tag(text: "创意", comments: "充满创意的灵感"),
        Tag(text: "科技", comments: "科技正在改变世界"),
        Tag(text: "心灵", comments: "关心内心的成长"),
        Tag(text: "美食", comments: "享受各种美味佳肴"),
        Tag(text: "艺术", comments: "艺术点亮生活"),
        Tag(text: "人文", comments: "探索不同的人文风情"),
        Tag(text: "旅行", comments: "旅行丰富人生"),
        Tag(text: "健康", comments: "健康生活是幸福基石"),
        Tag(text: "音乐", comments: "音乐的魅力无法抵挡"),
        Tag(text: "视觉", comments: "用视觉记录美好瞬间"),
        Tag(text: "时光", comments: "珍惜每个时光"),
        Tag(text: "书香", comments: "阅读带来智慧"),
        Tag(text: "星空", comments: "夜空中的星星璀璨"),
        Tag(text: "社交", comments: "通过社交连接世界"),
        Tag(text: "灵感", comments: "灵感源源不断"),
        Tag(text: "城市", comments: "城市探索充满惊喜"),
        Tag(text: "健身", comments: "锻炼身体让人充满活力"),
        Tag(text: "幸福", comments: "追求真正的幸福"),
        Tag(text: "手工", comments: "用双手创造美好"),
      ]
    }
  }

  public extension Participant {
    static func getSampleParticipants() -> [Participant] {
      return [
        Participant(name: "李雨宁", nickName: "小雨"),
        Participant(name: "陈宇轩", nickName: "宇宝"),
        Participant(name: "王心怡", nickName: "心心"),
        Participant(name: "张晨阳", nickName: "阳光"),
        Participant(name: "刘雅婷", nickName: "婷婷"),
        Participant(name: "赵天宇", nickName: "宇哥"),
        Participant(name: "黄思涵", nickName: "小涵"),
        Participant(name: "周俊杰", nickName: "俊俊"),
        Participant(name: "徐雨菲", nickName: "菲菲"),
        Participant(name: "林宝宝", nickName: "宝宝"),
      ]
    }
  }

  public extension Moment {
    static func getSampleMoments(count: Int, dateRange: ClosedRange<Date>? = nil) -> [Moment] {
      return (0 ..< count).map { _ in
        let randomDate: Date = {
          if let range = dateRange {
            let interval = range.upperBound.timeIntervalSince(range.lowerBound)
            let randomOffset = TimeInterval.random(in: 0 ... interval)
            return range.lowerBound.addingTimeInterval(randomOffset)
          }
          else {
            return Date.randomDate()
          }
        }()
        return Moment(timestamp: randomDate)
      }
    }
  }

  private struct ParticipantProperties {
    let note: String

    static let demo1 = Self(note: "实验室师兄，很瘦，有一个女儿。\n现在在深圳")
    static let demo2 = Self(note: "音乐爱好者，弹钢琴和吉他。\n常常去旅行，喜欢探索不同的音乐文化。")
    static let demo3 = Self(note: "热爱绘画，擅长油画。\n计划在未来举办个人艺术展。")
    static let demo4 = Self(note: "科技极客，参与过多个开源项目。\n下个月将在波士顿举行的技术大会演讲嘉宾。")
    static let demo5 = Self(note: "喜欢户外运动，尤其喜爱滑雪。\n每年都会参加滑雪俱乐部的冬季活动。")
    static let demo6 = Self(note: "影视评论家，撰写了多本影评。\n即将参加国际电影节，担任评审团成员。")
    static let demo7 = Self(note: "热衷植物学，拥有许多稀有植物。\n经常在社区举办植物分享会。")
    static let demo8 = Self(note: "时尚达人，经常发布时尚穿搭技巧。\n在社交媒体上拥有大量粉丝。")
    static let demo9 = Self(note: "志愿者，致力于环保事业。\n组织了多次社区垃圾清理活动。")
    static let demo10 = Self(note: "旅行作家，已出版多本畅销旅行游记。\n计划环球旅行以寻找灵感。")
    static let demo11 = Self(note: "摄影师，专注于人像摄影。\n在巴黎举办的摄影展上获得了奖项。")
    static let demo12 = Self(note: "烹饪大师，曾在米其林星级餐厅工作。\n将在本月末开设烹饪课程。")
    static let demo13 = Self(note: "网络安全专家，研究黑客攻防技术。\n在国际安全会议上做过多次演讲。")
    static let demo14 = Self(note: "社会活动家，致力于推动公益事业。\n创办了一个关注儿童教育的非营利组织。")
    static let demo15 = Self(note: "文化史研究员，专攻古代文明。\n最近在一本学术期刊上发表了重要论文。")
    static let demo16 = Self(note: "舞蹈家，擅长现代舞和芭蕾。\n曾在国际舞蹈比赛中获得金牌。")
    static let demo17 = Self(note: "游戏开发者，创作了多款热门游戏。\n正在制作一款全新的虚拟现实游戏。")
    static let demo18 = Self(note: "心理治疗师，帮助人们克服心理困扰。\n已出版一本畅销心理健康指南。")
    static let demo19 = Self(note: "音乐制作人，制作了多位艺人的专辑。\n计划在年底举办一场音乐盛典。")
    static let demo20 = Self(note: "创业家，创建了一家成功的科技初创公司。\n在《科技时代》杂志上有专访报道。")

    static let allDemos: [Self] = [
      .demo1,
      .demo2,
      .demo3,
      .demo4,
      .demo5,
      .demo6,
      .demo7,
      .demo8,
      .demo9,
      .demo10,
      .demo11,
      .demo12,
      .demo13,
      .demo14,
      .demo15,
      .demo16,
      .demo17,
      .demo18,
      .demo19,
      .demo20,
    ]
  }

  public enum TestImage {
    public static let symbols: [String] = [
      "star.fill",
      "cloud.sun.fill",
      "heart.circle.fill",
      "doc.richtext.fill",
      "moon.stars.fill",
      "film.fill",
      "paperplane.fill",
      "gamecontroller.fill",
      "leaf.fill",
      "hourglass.bottomhalf.fill",
    ]
  }

  public extension MediaItem {
    static func from(systemName: String) -> MediaItem? {
      if let data = UIImage(systemName: systemName)?.heicData() {
        let thumbnailData150px: Data? = try? UIImage.downsample(imageData: data, to: CGSize(width: 150, height: 150))
        let thumbnailData500px: Data? = try? UIImage.downsample(imageData: data, to: CGSize(width: 500, height: 500))
        let thumbnailData1000px: Data? = try? UIImage.downsample(imageData: data, to: CGSize(width: 1000, height: 1000))
        return MediaItem(
          data: data,
          mediaType: .image,
          pathExtension: "heic",
          thumbnailData150px: thumbnailData150px ?? data,
          thumbnailData500px: thumbnailData500px ?? data,
          thumbnailData1000px: thumbnailData1000px ?? data
        )
      }
      return nil
    }
  }

  private struct TitleAndDescription {
    ///  title for moment
    let title: String

    /// Description for moment
    let description: String
    static let demo1 = Self(title: "Evening Run at the Gym", description: "It's been a while since I came to the gym. Exercise feels so good. Still not in the best shape, but I'll keep working.")
    static let demo2 = Self(title: "Exploring City Cuisine", description: "Tried the famous local street food today. The taste is absolutely unforgettable.")
    static let demo3 = Self(title: "Journey to the Art Gallery", description: "Visited an art gallery and was deeply moved by various forms of art.")
    static let demo4 = Self(title: "Hiking in Natural Landscapes", description: "Took a hike through a mountainous trail, enjoying the breathtaking natural scenery.")
    static let demo5 = Self(title: "Live Music Concert", description: "Attended a mesmerizing live music concert. The power of music is truly enchanting.")
    static let demo6 = Self(title: "Paseo por la Playa", description: "Disfruté de un relajante paseo por la playa mientras el sol se ponía en el horizonte.")
    static let demo7 = Self(title: "Exploration de la Cuisine Locale", description: "Dégusté les délices culinaires de la région. Des saveurs incroyables !")
    static let demo8 = Self(title: "日本の風景を楽しむ", description: "美しい日本の自然風景を散歩しながら楽しんでいます。")
    static let demo9 = Self(title: "Un Giorno nel Museo", description: "Passato una giornata esplorando le opere d'arte e la storia in un museo locale.")
    static let demo10 = Self(title: "Abenteuer in den Bergen", description: "Eine Wanderung durch die Berge hat mir atemberaubende Ausblicke beschert.")
    static let demo11 = Self(title: "晚上去健身房跑步了", description: "好久没来了，运动果然很舒服。身体没到最佳状态，继续努力")
    static let demo12 = Self(title: "探索城市美食", description: "今天去尝试了当地有名的小吃摊，味道真是让人回味无穷。")
    static let demo13 = Self(title: "艺术画廊之旅", description: "参观了一家艺术画廊，深受不同形式的艺术震撼。")
    static let demo14 = Self(title: "自然风光徒步", description: "远足了一段山区路线，欣赏到了壮丽的自然景色。")
    static let demo15 = Self(title: "音乐会现场", description: "观看了一场精彩的音乐会，音乐的魔力让人陶醉其中。")

    static let allDemos: [Self] = [
      .demo1,
      .demo2,
      .demo3,
      .demo4,
      .demo5,
      .demo6,
      .demo7,
      .demo8,
      .demo9,
      .demo10,
      .demo11,
      .demo12,
      .demo13,
      .demo14,
      .demo15,
    ]
  }

  private extension Date {
    static func randomDate() -> Date {
      let currentDate = Date()
      let maxDaysAgo: TimeInterval = -60 * 24 * 60 * 60 // 60 days ago

      let timeInterval = TimeInterval.random(in: currentDate.addingTimeInterval(maxDaysAgo).timeIntervalSince1970 ... currentDate.timeIntervalSince1970)
      return Date(timeIntervalSince1970: timeInterval)
    }
  }

  private extension Array {
    var getRandomElements: [Element] {
      var array = self
      var result = [Element]()
      let counts = (0 ..< self.count).randomElement() ?? 0
      for _ in (0 ..< counts) {
        if let randomSetIndex = array.indices.randomElement() {
          result.append(array.remove(at: randomSetIndex))
        }
      }
      return result
    }
  }

#endif
