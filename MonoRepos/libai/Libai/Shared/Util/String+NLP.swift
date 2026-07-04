//
//  String+NLP.swift
//  Libai
//
//  Created by huahuahu on 2022/4/23.
//

import Foundation
import NaturalLanguage

extension String {
  func lemmatized() -> String {
    let tagger = NLTagger(tagSchemes: [.lemma])
    tagger.string = self

    var result = [String]()

    tagger.enumerateTags(in: startIndex ..< endIndex, unit: .word, scheme: .lemma) { tag, tokenRange in
      let stemForm = tag?.rawValue ?? String(self[tokenRange])
      result.append(stemForm)
      return true
    }

    return result.joined()
  }

  func tokenized() -> [String] {
    let tokenizer = NLTokenizer(unit: .word)
    tokenizer.string = self

    let result = tokenizer.tokens(for: startIndex ..< endIndex)
      .map { String(self[$0]) }
    return result
  }

  func getWords(of targets: [NLTag]) -> [String] {
    let tagger = NLTagger(tagSchemes: [.lexicalClass])
    tagger.string = self
    let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
    var result = [String]()
    tagger.enumerateTags(in: startIndex ..< endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in

      if let tag = tag, targets.contains(tag) {
        result.append(String(self[tokenRange]))
      }
      return true
    }
    return result
  }
}
