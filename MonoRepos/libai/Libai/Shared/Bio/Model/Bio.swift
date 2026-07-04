//
//  Bio.swift
//  Libai
//
//  Created by huahuahu on 2022/2/5.
//

import Foundation

enum BioType: Int, CaseIterable, Identifiable {
  // swiftlint:disable identifier_name
  case annal = 0
  case 才子传
  case 新唐书
  case 旧唐书
  case 翰林学士李公新墓碑
  case 草堂集序
  case 李翰林集序
  case 唐故翰林学士李君碣记
  // swiftlint:enable identifier_name
  var id: String {
    title
  }

  var displayType: DisplayType {
    switch self {
    case .annal:
      return .annalList
    case .才子传:
      return .text
    case .新唐书:
      return .text
    case .旧唐书:
      return .text
    case .翰林学士李公新墓碑:
      return .text
    case .草堂集序:
      return .text
    case .李翰林集序:
      return .text
    case .唐故翰林学士李君碣记:
      return .text
    }
  }

  var title: String {
    switch self {
    case .annal:
      return "编年"
    case .才子传:
      return "唐才子传·李白"
    case .新唐书:
      return "新唐书·李白传"
    case .旧唐书:
      return "旧唐书·李白传"
    case .翰林学士李公新墓碑:
      return "翰林学士李公新墓碑"
    case .草堂集序:
      return "草堂集序"
    case .李翰林集序:
      return "李翰林集序"
    case .唐故翰林学士李君碣记:
      return "唐故翰林学士李君碣记"
    }
  }

  var summary: String {
    switch self {
    case .annal:
      return "作者自己整理的，谨代表个人观点"
    case .才子传:
      return ""
    case .新唐书:
      return ""
    case .旧唐书:
      return ""
    case .翰林学士李公新墓碑:
      return ""
    case .草堂集序:
      return ""
    case .李翰林集序:
      return ""
    case .唐故翰林学士李君碣记:
      return ""
    }
  }

  var bioModel: BioModel? {
    switch self {
    case .annal:
      return nil
    case .才子传:
      return BioModel(rawText: String(dataSetName: "唐才子传"))
    case .新唐书:
      return BioModel(rawText: String(dataSetName: "新唐书"))
    case .旧唐书:
      return BioModel(rawText: String(dataSetName: "旧唐书"))
    case .翰林学士李公新墓碑:
      return BioModel(rawText: String(dataSetName: "翰林学士李公新墓碑"))
    case .草堂集序:
      return BioModel(rawText: String(dataSetName: "草堂集序"))
    case .李翰林集序:
      return BioModel(rawText: String(dataSetName: "李翰林集序"))
    case .唐故翰林学士李君碣记:
      return BioModel(rawText: String(dataSetName: "唐故翰林学士李君碣记"))
    }
  }
}

enum DisplayType {
  case annalList
  case text
}

struct BioModel {
  let rawText: String
}
