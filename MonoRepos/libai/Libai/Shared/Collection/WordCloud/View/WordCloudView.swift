//
//  WordCloudView.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/4/22.
//

import AlertToast
import CoreData
import SwiftUI

@MainActor
struct WordCloudView: View {
  @EnvironmentObject var settings: Settings
  @StateObject private var store = WordCloudStore()
  @State private var isPresenting = false
  @State private var filterModel = PoemFilterModel(genreOptions: [], lifeStage: [])

  @State private var wordCloudImage: UIImage?
  @State private var alertResult: Bool?
  @FetchRequest(sortDescriptors: [SortDescriptor(\.title, order: .forward)]) private var cdPoems: FetchedResults<CDPoem>

  @ViewBuilder
  var content: some View {
    WebView(webview: store.wordCloudModel.webView)
      .sheet(isPresented: $isPresenting, onDismiss: {
        hLog("dismissed", scenerio: .wordCloud)
        self.filterModel = store.filterModel
      }, content: {
        WordCloudPoemFilterView(
          filterModel: $filterModel,
          isPresenting: $isPresenting
        ) { [weak store] poemFilterModel in
          store?.filterModel = poemFilterModel
        }
        .theme(settings.pTheme)
        .presentationDetents([.medium, .large])
      })
  }

  private var allPoems: [Poem] {
    cdPoems.map { Poem($0) }.sorted {
      $0.title.chineseCompare($1.title) == .orderedAscending
    }
  }

  var shareButton: some View {
    Button {
      wordCloudImage = store.wordCloudModel.takeScreenshot()
    } label: {
      Image(systemName: SystemImage.share)
    }
    .disabled(!store.isShowingWordCloud)
    .sheet(isPresented: .init(get: {
      wordCloudImage != nil
    }, set: { _ in
      if !isPresenting {
        wordCloudImage = nil
      }
    }), content: {
      ActivityViewController(activityItems: [wordCloudImage as Any]) { type, success in
        hLog("\(String(describing: type)), \(success)", scenerio: .wordCloud)
        if type == .saveToCameraRoll {
          alertResult = success
        }
      }
      .theme(settings.pTheme)
    })
  }

  @ToolbarContentBuilder
  var toolBarContent: some ToolbarContent {
    ToolbarItemGroup(placement: .navigationBarTrailing) {
      Button {
        store.triggerNewDraw()
      } label: {
        Image(systemName: SystemImage.refresh)
      }
      .disabled(!store.isShowingWordCloud)

      Button {
        isPresenting = true
      } label: {
        Text(PredefinedString.filter)
      }
      .disabled(allPoems.isEmpty)

      shareButton
    }
  }

  private var alertToast: AlertToast {
    let title = alertResult == true ? PredefinedString.saveSuccess : PredefinedString.saveFailure
    return AlertToast(
      displayMode: .banner(.pop),
      type: .complete(.blue),
      title: title
    )
  }

  var body: some View {
    content
      .onChange(of: allPoems, initial: true, { _, newValue in
        store.poems = newValue
      })
      .toast(
        isPresenting: .init(get: {
          alertResult != nil
        }, set: { isPresenting in
          if !isPresenting {
            alertResult = nil
          }
        }),
        duration: 2,
        tapToDismiss: true
      ) {
        alertToast
      }
      .navigationTitle(PredefinedString.wordCloud)
      .toolbar {
        toolBarContent
      }
  }
}

struct WordCloudView_Previews: PreviewProvider {
  static var previews: some View {
    WordCloudView()
  }
}
