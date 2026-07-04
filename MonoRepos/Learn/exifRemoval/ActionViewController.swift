//
//  ActionViewController.swift
//  exifRemoval
//
//  Created by tigerguo on 2025/3/23.
//
import MobileCoreServices
import UIKit
import UniformTypeIdentifiers

class ActionViewController: UIViewController {
  private let imageView = UIImageView()
  private let statusLabel = UILabel()
  private let shareButton = UIButton(type: .system)
  private var image: UIImage?
  private var imageUrl: URL?

  override func loadView() {
    // 纯代码创建视图层级
    let view = UIView()
    view.backgroundColor = .systemBackground

    // 配置图片预览
    imageView.contentMode = .scaleAspectFit
    imageView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(imageView)

    // 状态标签
    statusLabel.text = "Processing..."
    statusLabel.textAlignment = .center
    statusLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(statusLabel)

    // 分享按钮
    shareButton.setTitle("Share", for: .normal)
    shareButton.addTarget(self, action: #selector(triggerShare), for: .touchUpInside)
    shareButton.translatesAutoresizingMaskIntoConstraints = false
    shareButton.isHidden = true
    view.addSubview(shareButton)

    // AutoLayout 约束
    NSLayoutConstraint.activate([
      imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
      imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
      imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),

      statusLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
      statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

      shareButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
      shareButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      shareButton.widthAnchor.constraint(equalToConstant: 200),
      shareButton.heightAnchor.constraint(equalToConstant: 44),
    ])

    self.view = view
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    loadInputImage()
  }

  private func loadInputImage() {
    guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
          let itemProvider = extensionItem.attachments?.first else {
      completeWithError()
      return
    }

    itemProvider.loadItem(forTypeIdentifier: UTType.image.identifier) { [weak self] item, _ in
      guard let self = self, let url = item as? URL else {
        self?.completeWithError()
        return
      }

      DispatchQueue.main.async {
        self.imageView.image = UIImage(contentsOfFile: url.path)
        self.image = UIImage(contentsOfFile: url.path)
        self.imageUrl = url
        self.processImage(url: url)
      }
    }
  }

  private func processImage(url: URL) {
    // 你的 EXIF 处理逻辑（保持与之前相同）
    // ...

    // 处理完成后更新 UI
    statusLabel.text = "EXIF Removed!"
    shareButton.isHidden = false
  }

  @objc private func triggerShare() {
    // 触发系统分享的逻辑（保持与之前相同）
    // ...// 1️⃣ 创建 NSItemProvider
    let itemProvider = NSItemProvider(contentsOf: imageUrl)!

    // 2️⃣ 包装成 NSExtensionItem
    let extensionItem = NSExtensionItem()
    itemProvider.registerFileRepresentation(
      forTypeIdentifier: UTType.image.identifier,
      fileOptions: .openInPlace,
      visibility: .all
    ) { completion in
      completion(self.imageUrl!, false, nil)
      return nil
    }

    extensionItem.attachments = [itemProvider]
    showSystemShareSheet(with: [imageUrl!])
    // trigger share
//        UIActivityItemProvider(placeholderItem: )

//        extensionContext?.completeRequest(returningItems: [extensionItem]) { expired in
//            DispatchQueue.main.async {
//                print(expired ? "失败" : "成功")
//            }
//        }
  }

  func showSystemShareSheet(with items: [Any]) {
    let activityVC = UIActivityViewController(
      activityItems: items,
      applicationActivities: nil
    )

    // 适配 iPad 的 Popover 样式
    if let popover = activityVC.popoverPresentationController {
      popover.sourceView = self.view
      popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
      popover.permittedArrowDirections = []
    }

    present(activityVC, animated: true)
  }

  private func completeWithError() {
    statusLabel.text = "Error Processing Image"
    extensionContext?.completeRequest(returningItems: nil)
  }
}
