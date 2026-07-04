import SwiftUI

enum ThemeColor: String, CaseIterable, Identifiable {
  case red
  case yellow

  var id: String { self.rawValue }
}

struct CalendareViewDemo: View {
  @State private var themeColor: ThemeColor = .red
  @State private var selectedDate: Date?

  var body: some View {
    VStack {
      Picker("Select View", selection: $themeColor) {
        ForEach(ThemeColor.allCases) { viewType in
          Text(viewType.rawValue).tag(viewType)
        }
      }
      .pickerStyle(SegmentedPickerStyle())
      .border(.blue, width: 1)
      .padding()

      ScrollView {
//              Text(verbatim: "a:")

        CalendarViewWrapper(themeColor: $themeColor, selectedDate: $selectedDate)
//                  .padding(.horizontal, 100)
          .border(.red, width: 1)
          .padding()
//                Text(verbatim: "wide text")
//                  .font(.title)
        if let selectedDate = selectedDate {
          Text("Selected Date: \(selectedDate.formatted())")
        }
        Button(action: {
          selectedDate = nil
        }) {
          Text("Clear Selected Date")
        }
        .disabled(selectedDate == nil)
        .padding()

        Button(action: {
          selectedDate = Date()
        }) {
          Text("Set Selected Date to Today")
        }
        .padding()
      }
      .navigationTitle("CalendarViewDemo")
      .navigationBarTitleDisplayMode(.inline)
    }
    .border(.green, width: 1)
    .padding(.horizontal, 20)
  }
}

// add preview
#Preview(body: {
  CalendareViewDemo()
})
