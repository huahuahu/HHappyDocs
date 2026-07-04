// The Swift Programming Language
// https://docs.swift.org/swift-book

import HFoundation
import SwiftUI

@MainActor
public struct EntryView: View {
  @Environment(\.supportEdit) var supportEdit: Bool

  @State private var showingSettings = false
  public init() {}

  public var body: some View {
    NavigationStack {
      ImageSelectionView()
        .toolbar {
          EntryViewToolbarContent()
        }
        .navigationTitle(Text(navigationTitle))
        .navigationBarTitleDisplayMode(.inline)
    }
  }

  private var navigationTitle: String {
    supportEdit ? ExifString.Common.appNameEditor.hDocLocalized() : ExifString.Common.appNameViewer.hDocLocalized()
  }
}

@MainActor
struct EntryViewToolbarContent: ToolbarContent {
  @State var showingSettings: Bool = false
  @State var showingPromotion: Bool = false
  @Environment(\.supportEdit) var supportEdit: Bool

  var body: some ToolbarContent {
    ToolbarItem(placement: .topBarLeading) {
      Button {
        showingSettings.toggle()
      } label: {
        Label {
          Text(ExifString.Common.settings.hDocLocalized())
        } icon: {
          Image(hExifSymbol: .settings)
        }
      }
      .sheet(isPresented: $showingSettings) {
        SettingsScreen()
      }
    }

    if !supportEdit {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          showingPromotion.toggle()
        } label: {
          Label {
            Text(ExifString.Common.settings.hDocLocalized())
          } icon: {
            Image(hExifSymbol: .promote)
          }
        }
        .sheet(isPresented: $showingPromotion) {
          PromotionScreen()
        }
      }
    }
  }
}

#Preview("Don't support edit") { @MainActor in
  EntryView()
}

#Preview("Support edit") { @MainActor in
  EntryView()
    .environment(\.supportEdit, true)
}
