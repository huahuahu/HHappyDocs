import SwiftUI

struct CalendarListView: View {
  var body: some View {
    List(CalendarListEntry.allCases) { entry in
      NavigationLink(value: NavigationTarget.calendar(entry: entry)) {
        VStack {
          Text(entry.title)
        }
      }
    }
    .navigationTitle(Entry.calendar.title)
  }
}

#Preview {
  MediaLearnList()
}
