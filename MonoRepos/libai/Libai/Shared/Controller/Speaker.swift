//
//  Speaker.swift
//  Libai
//
//  Created by huahuahu on 2021/12/26.
//

import AVFoundation
import Foundation

class SpeakerController {
  static let shared = SpeakerController()

  var speakerMap = [Poem: Speaker]()

  private init() {}

  func speak(poem: Poem) {
    if speakerMap[poem] != nil {
      hLog("huahuahu \(poem.title) speaking")
      return
    }
    else {
      let speaker = Speaker(poem: poem)
      speakerMap[poem] = speaker
      speaker.speak()
      hLog("huahuahu start speak \(poem.title)")
    }
  }

  func stopSpeak(poem: Poem) {
    let speaker = speakerMap.removeValue(forKey: poem)
    speaker?.stopSpeak()
  }
}

class Speaker {
  init(poem: Poem) {
    hLog("huahuahu init speaker for poem \(poem.title)")
    self.poem = poem
  }

  private let poem: Poem
  private var synthesizer: AVSpeechSynthesizer?

  func speak() {
    stopSpeak()
    let utterance = AVSpeechUtterance(string: poem.title)
    utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
    utterance.rate = 0.5

    synthesizer = AVSpeechSynthesizer()
    synthesizer?.speak(utterance)
  }

  func stopSpeak() {
    synthesizer?.stopSpeaking(at: .word)
  }
}
