//
//  MomentGroupIdView.swift
//  HDiary
//
//  Created by tigerguo on 2023/11/7.
//

import HDiaryModel
import HFoundation
import SwiftUI

struct MomentGroupIdView: View {
  let groupID: InstanceGroup<Moment>.GroupIdentifier
  var body: some View {
    content
      .font(.title2)
      .fontDesign(.rounded)
      .foregroundStyle(.primary)
      .bold()
  }

  @ViewBuilder
  private var content: some View {
    switch groupID {
    case .future:
      Text(DiaryStringKey.Common.Date.future)
    case .today:
      Text(DiaryStringKey.Common.Date.today)

    case .yesterday:
      Text(DiaryStringKey.Common.Date.yesterday)
    case .recent7Days:
      Text(DiaryStringKey.Common.Date.recent7Days)
    case .thisYear(month: let date):
      Text(date, format: .dateTime.month(.wide))
    case .previousYear(year: let date):
      Text(date, format: .dateTime.year(.defaultDigits))
    case .ungrouped:
      Text(DiaryStringKey.Common.Date.ungrouped)
    }
  }
}

#Preview("common") {
  return List {
    MomentGroupIdView(groupID: .future)
      .environment(\.locale, .cnMainland)
    MomentGroupIdView(groupID: .future)
      .environment(\.locale, .en)

    MomentGroupIdView(groupID: .today)
      .environment(\.locale, .cnMainland)
    MomentGroupIdView(groupID: .today)
      .environment(\.locale, .en)

    MomentGroupIdView(groupID: .recent7Days)
      .environment(\.locale, .cnMainland)
    MomentGroupIdView(groupID: .recent7Days)
      .environment(\.locale, .en)

    MomentGroupIdView(groupID: .yesterday)
      .environment(\.locale, .cnMainland)
    MomentGroupIdView(groupID: .yesterday)
      .environment(\.locale, .en)

    MomentGroupIdView(groupID: .ungrouped)
      .environment(\.locale, .cnMainland)
    MomentGroupIdView(groupID: .ungrouped)
      .environment(\.locale, .en)
  }
}

#Preview("month-Sep") {
  let calendar = Calendar.current

  // 指定年、月、日、时、分、秒
  var components = DateComponents()
  components.year = 2023
  components.month = 9

  let sep = calendar.date(from: components)

  return List {
    MomentGroupIdView(groupID: .thisYear(month: sep!))
      .environment(\.locale, .cnMainland)
    MomentGroupIdView(groupID: .thisYear(month: sep!))
      .environment(\.locale, .en)
  }
}

#Preview("year-2019") {
  let calendar = Calendar.current

  // 指定年、月、日、时、分、秒
  var components = DateComponents()
  components.year = 2019

  let date = calendar.date(from: components)!
  return List {
    MomentGroupIdView(groupID: .previousYear(year: date))
      .environment(\.locale, .cnMainland)
    MomentGroupIdView(groupID: .previousYear(year: date))
      .environment(\.locale, .en)
  }
}
