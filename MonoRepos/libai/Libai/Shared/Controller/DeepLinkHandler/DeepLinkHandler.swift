//
//  DeepLinkHandler.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/5/8.
//

import Combine
import CoreData
import Foundation
import SwiftUI
#if os(iOS)
  import UIKit
#endif

class DeepLinkHandler: ObservableObject {
  enum Constants {
    static let host = "www.libaiapp.com"
    static let poemDetailPath = "poemDetail"
    static let random = "random"
  }

  private var cancellables = Set<AnyCancellable>()
  @Published private var latestUrl: URL?

  private var navigationModel: HNavigationModel?
  init() {
    $latestUrl
      .sink { [weak self] newUrl in
        guard let self = self else { return }
        guard let newUrl = newUrl else { return }
        self.handleNewUrl(newUrl)
      }
      .store(in: &cancellables)
  }

  func setNavigationModel(_ newModel: HNavigationModel) {
    navigationModel = newModel
  }

  func setLatestUrl(_ url: URL) {
    hLog("openurl \(url)", scenerio: .deepLink)
    latestUrl = url
  }

  func handleNewUrl(_ url: URL) {
    hLog("url \(url)", scenerio: .default)
    guard let urlComponent = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
      hLog("can't get urlComponent \(url)", scenerio: .deepLink)
      return
    }
    guard urlComponent.host?.lowercased() == Constants.host else {
      hLog("Invalid host, skip", scenerio: .deepLink)
      return
    }
    prepareNavigation()

    let subPaths = urlComponent.path.split(separator: "/")
    if subPaths.count == 2 {
      let firstComponent = String(subPaths[0]).lowercased()
      if firstComponent == Constants.poemDetailPath.lowercased() {
        handleOpenPoem(String(subPaths[1]))
        latestUrl = nil
      }
    }
  }

  private func prepareNavigation() {
    #if os(iOS)

      guard let rootVC = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow?.rootViewController else {
        hLog("no rootVC, skip", scenerio: .deepLink)
        return
      }

      if rootVC.presentedViewController != nil {
        hLog("has presented vc, try dismiss", scenerio: .deepLink)
        rootVC.dismiss(animated: true) {
          hLog("Dismiss finish", scenerio: .deepLink)
        }
      }
      else {
        hLog("No presented vc, return", scenerio: .deepLink)
      }
    #endif
  }

  private func handleOpenPoem(_ poemID: String) {
    hLog("Open poem \(poemID)", scenerio: .deepLink)
    if poemID == Constants.random {
      openRandomPoem()
      return
    }

    guard let poemIDInt = Int(poemID) else {
      hLog("Invalid poemID \(poemID)", scenerio: .deepLink)
      return
    }

    if let navigationModel = navigationModel {
      navigationModel.append(newItem: PoemKey(poemID: poemIDInt))
      return
    }

    #if os(iOS)
      guard let rootVC = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow?.rootViewController else {
        hLog("no rootVC, skip", scenerio: .deepLink)
        return
      }

      Task { @MainActor in
        let vc = UIHostingController(rootView: PoemDetailView(poemID: poemIDInt).theme(Settings.shared.pTheme))
        vc.overrideUserInterfaceStyle = .init(Settings.shared.pTheme)
        let navigationVC = UINavigationController(rootViewController: vc)

        rootVC.present(navigationVC, animated: true, completion: {
          hLog("Presend vc for poem \(poemID)", scenerio: .deepLink)
        })
      }
    #endif
  }

  func openRandomPoem() {
    hLog("Open random poem", scenerio: .deepLink)
    let fetchRequest = NSFetchRequest<CDPoem>(entityName: CDPoem.entityName)

    do {
      let poems = try HCoreDataStack.shared.privateManagedContext.fetch(fetchRequest)
      guard let poem = poems.randomElement() else {
        hLog("can't find random poem", scenerio: .deepLink)
        return
      }
      hLog("Open random poem \(poem.id)", scenerio: .deepLink)
      self.prepareNavigation()
      self.handleOpenPoem("\(poem.id)")
    }
    catch {
      hLog("Open random poem failed with error \(error)", scenerio: .deepLink)
    }
  }
}
