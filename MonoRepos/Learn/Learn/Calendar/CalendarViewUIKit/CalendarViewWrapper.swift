//
//  CalendarViewWrapper.swift
//  Learn
//
//  Created by tigerguo on 2024/11/14.
//

import SwiftUI
import UIKit

// import

// Your UIViewRepresentable wrapper for the custom UIView
struct CalendarViewWrapper: UIViewRepresentable {
  // Add any properties or data bindings here if needed

  @Binding var themeColor: ThemeColor
  @Binding var selectedDate: Date?

  init(themeColor: Binding<ThemeColor>, selectedDate: Binding<Date?>) {
    self._themeColor = themeColor
    self._selectedDate = selectedDate
    Log.common.info("CalendarViewWrapper init")
  }

  let calendar = Calendar(identifier: .gregorian)
  func makeUIView(context: Context) -> UICalendarView {
    Log.common.info("CalendarViewWrapper UICalendarView")
    // Create the calendar view.
    let calendarView = UICalendarView()

//
//
//        // Set the calendar displayed by the view.
    calendarView.calendar = calendar

    // Set the calendar view's locale.
//        calendarView.locale = Locale(identifier: "zh_TW")

    // Set the font design to the rounded system font.
    calendarView.fontDesign = .rounded
    calendarView.delegate = context.coordinator
//      calendarView.frame = CGRect(x: 0, y: 0, width: 300, height: 300)

//        calendarView.visibleDateComponents = DateComponents(
//            calendar: gregorianCalendar,
//            year: 2024,
//            month: 2,
//            day: 1
//        )

    context.coordinator.calendarView = calendarView

    let dateSelection = UICalendarSelectionSingleDate(delegate: context.coordinator.selectionSingleDateDelegate)
    calendarView.selectionBehavior = dateSelection
    // https://stackoverflow.com/a/75849907
    calendarView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
    calendarView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    return calendarView
  }

  func updateUIView(_ uiView: UICalendarView, context: Context) {
    Log.common.info("CalendarViewWrapper update UICalendarView")
    context.coordinator.updateThemeColor(themeColor, selectedDate: selectedDate)
    // Update the UIView if needed when SwiftUI view state changes
  }

  // Create the Coordinator instance
  func makeCoordinator() -> Coordinator {
    Log.common.info("CalendarViewWrapper makeCoordinator")
    return Coordinator(parent: self, calendar: calendar, themeColor: themeColor)
  }

  // Coordinator to handle delegate methods
  class Coordinator: NSObject, UICalendarViewDelegate {
    var parent: CalendarViewWrapper
    let calendar: Calendar
    var decorations: [Date: UICalendarView.Decoration] = [:]
    weak var calendarView: UICalendarView?
    let selectionSingleDateDelegate = SelectionSingleDateDelegate()

    private var themeColor: ThemeColor

    init(parent: CalendarViewWrapper, calendar: Calendar, themeColor: ThemeColor) {
      Log.common.info("CalendarViewWrapper Coordinator init")
      self.parent = parent
      self.calendar = calendar
      self.themeColor = themeColor
      super.init()
      self.prepareDecorations()
      selectionSingleDateDelegate.onDateSelected = { [weak self] dateComponents in
        self?.parent.selectedDate = dateComponents?.date
      }
//            decorations
    }

    func updateThemeColor(_ newColor: ThemeColor, selectedDate: Date?) {
      self.themeColor = newColor

      calendarView?.tintColor = newColor.uiColor
      prepareDecorations()
      if let calendarView {
        let componentsArray = {
          guard let date = calendar.date(from: calendarView.visibleDateComponents),
                let range = calendar.range(of: .day, in: .month, for: date) else {
            return [DateComponents]()
          }

          return range.compactMap { day -> DateComponents in
            var components = calendarView.visibleDateComponents
            components.day = day
            return components
          }
        }()

//            return

        calendarView.reloadDecorations(forDateComponents: componentsArray, animated: true)
      }

      Log.common.info("update theme color with selected date \(selectedDate?.debugDescription ?? "nil")")
//      if selectedDate == nil {
      if let singleSelection = calendarView?.selectionBehavior as? UICalendarSelectionSingleDate {
        let dateComponent = selectedDate.map { calendar.dateComponents([.year, .month, .day], from: $0) }
        singleSelection.setSelected(dateComponent, animated: true)
//        }
      }

//        parent.
    }

    private func prepareDecorations() {
      let today = DateComponents(
        calendar: calendar,
        year: calendar.component(.year, from: Date()),
        month: calendar.component(.month, from: Date()),
        day: calendar.component(.day, from: Date())
      )

      // Create a calendar decoration for Valentine's day.
      let heart = UICalendarView.Decoration.image(
        UIImage(systemName: "heart.fill"),
        color: themeColor.uiColor,
        size: .large
      )
      if let todayDate = today.date {
        decorations[todayDate] = heart
      }

      if let tomorrow = getDaysAfterDate(for: today.date, dayCount: 1) {
        decorations[tomorrow] = UICalendarView.Decoration.image(
          UIImage(systemName: "heart.circle"),
          color: themeColor.uiColor,
          size: .medium
        )
      }

      if let future = getDaysAfterDate(for: today.date, dayCount: 2) {
        decorations[future] = UICalendarView.Decoration.default(color: themeColor.uiColor, size: .large)
      }
      if let future = getDaysAfterDate(for: today.date, dayCount: 3) {
        decorations[future] = UICalendarView.Decoration.default(color: themeColor.uiColor, size: .medium)
      }

      if let future = getDaysAfterDate(for: today.date, dayCount: 4) {
        decorations[future] = UICalendarView.Decoration.default(color: themeColor.uiColor, size: .small)
      }

      if let future = getDaysAfterDate(for: today.date, dayCount: 5) {
        decorations[future] = UICalendarView.Decoration.customView({
          let swiftUIView = Text("🚀sdfasdfas")
          let hostingController = UIHostingController(rootView: swiftUIView)
          return hostingController.view
        })
      }

      if let future = getDaysAfterDate(for: today.date, dayCount: 6) {
        decorations[future] = UICalendarView.Decoration.customView({
          let swiftUIView = Text("🚀")
          let hostingController = UIHostingController(rootView: swiftUIView)
          return hostingController.view
        })
      }

      if let future = getDaysAfterDate(for: today.date, dayCount: 7) {
        decorations[future] = UICalendarView.Decoration.customView({
          let swiftUIView =
            Circle()
              .stroke(self.themeColor.swiftUIColor, lineWidth: 1) // Border color and width
//              .frame(width: 100, height: 100) // Set the size of the circle

          let hostingController = UIHostingController(rootView: swiftUIView)
          return hostingController.view
        })
      }

      if let future = getDaysAfterDate(for: today.date, dayCount: 8) {
        decorations[future] = UICalendarView.Decoration.customView({
//              let swiftUIView = Text("5 \(Image(systemName: "star.fill"))")
//                  .font(.caption)
//                  .imageScale(.small)
//                  .foregroundStyle(.secondary)

          let swiftUIView = HStack(spacing: 0) {
            Text("5 ")
              .font(.caption)
              .foregroundStyle(.secondary)

            Image(systemName: "star.fill")
              .foregroundColor(self.themeColor.swiftUIColor)
              .imageScale(.small)
              .font(.caption)
          }

          let hostingController = UIHostingController(rootView: swiftUIView)
          return hostingController.view
        })
      }

//      Log.common.info("decorations \(self.decorations)")
    }

    func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
      // Get a copy of the date components that only contain
      // the calendar, year, month, and day.
      let day = DateComponents(
        calendar: dateComponents.calendar,
        year: dateComponents.year,
        month: dateComponents.month,
        day: dateComponents.day
      )

      if let date = day.date {
//                Log.common.info("day \(day)")
        return decorations[date]
      }
      else {
        return nil
      }
    }

    func getDaysAfterDate(for today: Date?, dayCount: Int) -> Date? {
      if let todayDate = today,
         let tomorrow = calendar.date(byAdding: .day, value: dayCount, to: todayDate) {
        return tomorrow
      }
      return nil
    }
  }

  // implement SelectionSingleDateDelegate
  class SelectionSingleDateDelegate: NSObject, UICalendarSelectionSingleDateDelegate {
    var onDateSelected: ((DateComponents?) -> Void)?
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
      Log.common.info("Selected date: \(dateComponents?.debugDescription ?? "")")
      onDateSelected?(dateComponents)
    }

    func dateSelection(_ selection: UICalendarSelectionSingleDate, canSelectDate dateComponents: DateComponents?) -> Bool {
//            Log.common.info("canSelectDate: \(dateComponents?.debugDescription ?? "") ")
      return true
    }
  }
}

extension ThemeColor {
  var uiColor: UIColor {
    switch self {
    case .red:
      return UIColor.red
    case .yellow:
      return UIColor.yellow
    }
  }

  var swiftUIColor: Color {
    switch self {
    case .red:
      return Color.red
    case .yellow:
      return Color.yellow
    }
  }
}
