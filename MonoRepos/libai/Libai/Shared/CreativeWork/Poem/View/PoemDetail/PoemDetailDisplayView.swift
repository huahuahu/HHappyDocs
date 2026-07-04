//
//  PoemDetailDisplayView.swift
//  Libai
//
//  Created by huahuahu on 2022/2/6.
//

import Intents
import SwiftUI

struct PoemDetailDisplayView: View {
  @State var annotate: String?

  let poemDetail: PoemDetail

  private func addIntent() {
    let intent = PoemIntent()

    INInteraction(intent: intent, response: nil).donate { error in
      if let error = error {
        hLog("Donate Poem Intent error \(error)", scenerio: .wiget)
      }
      else {
        hLog("Donate Poem Intent Success", scenerio: .wiget)
      }
    }
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 10) {
        PoemTitleView(title: poemDetail.poem.title)
        HStack {
          PoemGenreView(genre: poemDetail.poem.genre)
          AgeView(age: poemDetail.poem.age)
        }
        TagsView(tags: poemDetail.poem.tags)
        PoemLocationList(locationIds: poemDetail.poem.locationIds)
        PoemContentView(content: poemDetail.displayContent.markdownToAttributed(), annotate: $annotate)
        PoemModernChineseView(modernChinese: poemDetail.poem.plainChinese)
          .padding(.bottom)
      }
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          FavPoemButton(poemID: poemDetail.poem.id)
        }
      }
//      .toolbar(content: {
//        ToolbarItemGroup(placement: .navigationBarTrailing) {
//          Button("停止", action: {
//            SpeakerController.shared.stopSpeak(poem: poemDetail.poem)
//          })
//          Button("朗读", action: {
//            SpeakerController.shared.speak(poem: poemDetail.poem)
//          })
//        }
//      })
    }
    .background(Color.primaryBackground)
    .onDisappear {
      SpeakerController.shared.stopSpeak(poem: poemDetail.poem)
    }.sheet(isPresented: Binding(get: {
      annotate != nil
    }, set: { traction in
      hLog("traction \(traction)")
    })) {
      annotate = nil
    } content: {
      Text(annotate ?? "no option")
    }
    .onAppear {
      addIntent()
    }
  }
}

struct PoemDetailDisplayView_Previews: PreviewProvider {
  static var previews: some View {
    PoemDetailDisplayView(poemDetail: .demo)
  }
}
