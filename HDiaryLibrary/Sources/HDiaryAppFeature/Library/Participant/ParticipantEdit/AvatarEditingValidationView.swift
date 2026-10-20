#if DEBUG && os(iOS)
  import HDiaryModel
  import PhotosUI
  import SwiftData
  import SwiftUI

  /// Opt-in, isolated UI validation. No access to the user's or CloudKit's store.
  struct AvatarEditingValidationView: View {
    static var isEnabled: Bool {
      ProcessInfo.processInfo.environment["HDIARY_AVATAR_EDIT_VALIDATION"] == "1" || opensCropDirectly
    }

    static var opensCropDirectly: Bool {
      ProcessInfo.processInfo.environment["HDIARY_AVATAR_CROP_VALIDATION"] == "1"
    }

    @State private var fixture = AvatarEditingValidationFixture()
    @State private var navigation = NavigationStore()
    @State private var largeText = ProcessInfo.processInfo.environment["HDIARY_AVATAR_LARGE_TEXT"] == "1"

    var body: some View {
      NavigationStack {
        if Self.opensCropDirectly {
          AvatarEditingFailureValidationView(fixture: fixture)
        }
        else {
          List {
            Toggle("最大辅助功能字号", isOn: $largeText)
            NavigationLink("新建人物") { ParticipantAddView() }
            NavigationLink("已有头像的人物详情") { ParticipantDetailView(participant: fixture.participant) }
            NavigationLink("加载与编码失败验证") { AvatarEditingFailureValidationView(fixture: fixture) }
            Section("当前人物") {
              AvatarEditingValidationParticipants()
            }
          }
          .navigationTitle("头像编辑验证")
        }
      }
      .modelContainer(fixture.container)
      .environment(navigation)
      .dynamicTypeSize(largeText ? .accessibility5 : .large)
    }
  }

  private struct AvatarEditingValidationParticipants: View {
    @Query private var participants: [Participant]

    var body: some View {
      ForEach(participants) { participant in
        NavigationLink { ParticipantDetailView(participant: participant) } label: {
          HStack {
            ParticipantAvatarView(participant: participant, size: 48)
            Text(participant.displayName)
          }
        }
      }
    }
  }

  private struct AvatarEditingFailureValidationView: View {
    let fixture: AvatarEditingValidationFixture
    @State private var editor: AvatarEditingSession

    init(fixture: AvatarEditingValidationFixture) {
      self.fixture = fixture
      let editor = fixture.makeEditor()
      if AvatarEditingValidationView.opensCropDirectly {
        editor.begin(PhotosPickerItem(itemIdentifier: "validation"))
      }
      self._editor = State(initialValue: editor)
    }

    var body: some View {
      @Bindable var fixture = fixture
      Form {
        AvatarSelectionView(participant: fixture.participant, editor: editor)
        Section("故障注入（仅验证）") {
          Toggle("下次加载失败", isOn: $fixture.failNextLoad)
          Toggle("下次编码失败", isOn: $fixture.failNextEncoding)
          Button("加载测试照片") { editor.begin(PhotosPickerItem(itemIdentifier: "validation")) }
          Text(fixture.participant.avatar == fixture.originalAvatar ? "原头像数据未变" : "头像数据已更新")
        }
      }
      .navigationTitle("失败重试验证")
    }
  }

  @Observable
  private final class AvatarEditingValidationFixture {
    let container: ModelContainer
    let participant = Participant.create(name: "头像验证", nickName: "小虎")
    let originalAvatar: Data?
    var failNextLoad = false
    var failNextEncoding = false

    init() {
      do {
        container = try ModelContainer(
          for: Moment.self, Tag.self, Participant.self, MediaItem.self,
          configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
        originalAvatar = Self.photo().pngData()
        participant.avatar = originalAvatar
        container.mainContext.insert(participant)
        try container.mainContext.save()
      }
      catch { fatalError("Could not create avatar validation fixture: \(error)") }
    }

    func makeEditor() -> AvatarEditingSession {
      AvatarEditingSession(loadPhoto: { item in
        try await Task.sleep(for: .seconds(1))
        if self.failNextLoad {
          self.failNextLoad = false
          throw AvatarEditingSession.Failure.invalidImage
        }
        return item.itemIdentifier == "validation" ? Self.photo() : try await AvatarEditingSession.loadPhoto(item)
      }, encode: { image in
        if self.failNextEncoding {
          self.failNextEncoding = false
          return nil
        }
        return image.pngData()
      })
    }

    private static func photo() -> UIImage {
      let format = UIGraphicsImageRendererFormat()
      format.scale = 1
      return UIGraphicsImageRenderer(size: CGSize(width: 900, height: 600), format: format).image { renderer in
        UIColor.systemTeal.setFill()
        renderer.fill(CGRect(x: 0, y: 0, width: 900, height: 600))
        UIColor.systemOrange.setFill()
        renderer.cgContext.fillEllipse(in: CGRect(x: 350, y: 200, width: 200, height: 200))
        UIColor.white.setFill()
        renderer.fill(CGRect(x: 50, y: 50, width: 80, height: 80))
        renderer.fill(CGRect(x: 770, y: 470, width: 80, height: 80))
      }
    }
  }
#endif
