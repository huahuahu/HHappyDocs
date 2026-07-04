//
//  TestNLPBasic.swift
//  LibaiTests
//
//  Created by huahuahu on 2022/4/23.
//

@testable import Libai
import NaturalLanguage
import XCTest

class TestNLPBasic: XCTestCase {
  private let sampleText = """
  君不见黄河之水天上来，奔流到海不复回。
  君不见高堂明镜悲白发，朝如青丝暮成雪。
  人生得意须尽欢，莫使金樽空对月。
  天生我材必有用，千金散尽还复来。
  烹羊宰牛且为乐，会须一饮三百杯。
  岑夫子，丹丘生，将进酒，杯莫停。
  与君歌一曲，请君为我倾耳听。
  钟鼓馔玉不足贵，但愿长醉不愿醒。
  古来圣贤皆寂寞，惟有饮者留其名。
  陈王昔时宴平乐，斗酒十千恣欢谑。
  主人何为言少钱，径须沽取对君酌。
  五花马、千金裘，呼儿将出换美酒，与尔同销万古愁。
  """

  func testEmbedding() throws {
    let embedding = NLEmbedding.wordEmbedding(for: .english)
    XCTAssertNotNil(embedding)
    let similarWords = embedding?.neighbors(for: "rain", maximumCount: 10)
    similarWords?.forEach { word, distance in
      print("word \(word), distance \(distance)")
    }
  }

  func testLemma() {
    let text = "This is text with plurals such as geese, people, and millennia."
    let tagger = NLTagger(tagSchemes: [.lemma])
    tagger.string = text
    print("\(#function) ", terminator: "")
    tagger.enumerateTags(in: text.startIndex ..< text.endIndex, unit: .word, scheme: .lemma) { tag, range in
      let stemForm = tag?.rawValue ?? String(text[range])

      print(stemForm, terminator: "")
      return true
    }
  }

  func testChineseTokenize() {
    let result = sampleText.tokenized()
    print("\(#function), \(result)")
  }

  func testChineseGetNoun() {
    let result = sampleText.getWords(of: [.noun])
    print("\(#function), \(result)")
  }

  func testPerformanceExample() throws {
    // This is an example of a performance test case.
    measure {
      // Put the code you want to measure the time of here.
    }
  }
}
