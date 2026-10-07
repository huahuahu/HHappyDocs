#if DEBUG && os(iOS)
  import HDiaryModel
  import Observation
  import SwiftUI
  import UIKit

  /// In-memory controls for reproducing Issue #43's interaction and failure cases.
  struct ParticipantAvatarPreviewValidationView: View {
    @State private var fixture = AvatarPreviewValidationFixture()
    @State private var supportsPreview = true
    @State private var refreshCount = 0

    var body: some View {
      NavigationStack {
        List {
          Section("被测头像") {
            HStack {
              ParticipantAvatarView(
                participant: fixture.current, size: 64, supportsPreview: supportsPreview,
                loader: fixture.loader, preview: fixture.preview
              )
              Text(fixture.current.nickName)
              Spacer()
              Button("刷新 \(refreshCount)") { refreshCount += 1 }
                .buttonStyle(.borderless)
            }
          }
          Section("原图与状态") {
            Button("更换为 B 原图") { fixture.current.avatar = fixture.secondImage }
            Button("恢复 A 原图") { fixture.current.avatar = fixture.firstImage }
            Button("切换联系人") {
              fixture.current = fixture.current === fixture.first ? fixture.second : fixture.first
            }
            Button("移除头像") { fixture.current.avatar = nil }
            Button("无效图片") { fixture.current.avatar = Data([0, 1, 2]) }
            Button("透明图片") { fixture.current.avatar = ParticipantPreviewAvatar.transparentImage() }
            Toggle("允许预览", isOn: $supportsPreview)
          }
          Section("故障与生命周期") {
            Button("下一次文件写入失败") { fixture.operations.failNextWrite = true }
            Button("暂停加载新头像") {
              fixture.operations.pausesLoading = true
              fixture.current.avatar = AvatarPreviewValidationFixture.image("加载完成", width: 600)
            }
            Button("完成图片加载") { fixture.operations.finishLoading() }
            Button("预览期间刷新父视图") {
              fixture.previewRefreshPending = true
            }
            Text(fixture.previewRefreshPending ? "打开预览后会自动刷新" : "刷新次数：\(refreshCount)")
          }
        }
        .navigationTitle("头像预览验收")
        .onChange(of: fixture.preview.previewURL) {
          if fixture.preview.previewURL != nil, fixture.previewRefreshPending {
            refreshCount += 1
            fixture.previewRefreshPending = false
          }
        }
      }
    }
  }

  @MainActor @Observable
  private final class AvatarPreviewValidationFixture {
    let firstImage = AvatarPreviewValidationFixture.image("A 原图", width: 800)
    let secondImage = AvatarPreviewValidationFixture.image("B 原图", width: 1200)
    let first: Participant
    let second: Participant
    var current: Participant
    var previewRefreshPending = false
    let operations = AvatarPreviewValidationOperations()

    @ObservationIgnored lazy var loader = ParticipantAvatarLoader(
      store: ParticipantAvatarImageStore(decode: operations.decode)
    )

    @ObservationIgnored lazy var preview = ParticipantAvatarPreview(prepareFile: operations.prepareFile)

    init() {
      first = Participant.create(name: "联系人 A", nickName: "联系人 A", avatar: firstImage)
      second = Participant.create(name: "联系人 B", nickName: "联系人 B", avatar: secondImage)
      current = first
    }

    static func image(_ title: String, width: CGFloat) -> Data {
      let format = UIGraphicsImageRendererFormat()
      format.scale = 1
      let size = CGSize(width: width, height: width * 0.75)
      return UIGraphicsImageRenderer(size: size, format: format).pngData { _ in
        UIColor.systemTeal.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        UIColor.systemYellow.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: width * 0.25, height: size.height))
        (title as NSString).draw(at: CGPoint(x: width * 0.3, y: width * 0.3), withAttributes: [
          .font: UIFont.systemFont(ofSize: width * 0.09, weight: .bold),
          .foregroundColor: UIColor.black,
        ])
      }
    }
  }

  @MainActor
  private final class AvatarPreviewValidationOperations {
    var failNextWrite = false
    var pausesLoading = false
    private var loadContinuation: CheckedContinuation<Void, Never>?

    func decode(_ data: Data, size: Int) async -> UIImage? {
      if pausesLoading {
        await withCheckedContinuation { loadContinuation = $0 }
      }
      return await ParticipantAvatarImage.decode(data, maxPixelSize: size)
    }

    func prepareFile(_ data: Data) async throws -> URL {
      if failNextWrite {
        failNextWrite = false
        // Exercise a real filesystem failure, without changing the real preview directory.
        let obstruction = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data([0]).write(to: obstruction)
        defer { try? FileManager.default.removeItem(at: obstruction) }
        return try await ParticipantAvatarPreviewFiles(root: obstruction).prepare(data)
      }
      return try await ParticipantAvatarPreviewFiles.shared.prepare(data)
    }

    func finishLoading() {
      pausesLoading = false
      loadContinuation?.resume()
      loadContinuation = nil
    }
  }
#endif
