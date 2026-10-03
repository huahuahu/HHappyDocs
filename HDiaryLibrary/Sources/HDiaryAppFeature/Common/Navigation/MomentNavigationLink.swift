#if os(iOS)

import HDiaryModel
import SwiftUI

/// A namespace per rendered link distinguishes the same moment in different lists.
/// The model UUID remains stable across edits and sorting; never use a row index.
struct MomentNavigationLink<Label: View>: View {
  let moment: Moment
  @ViewBuilder var label: () -> Label

  @Namespace private var namespace
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private var destination: HDiaryDestination {
    // Choose the route before presentation, keeping the detail's identity stable
    // throughout editing and interactive dismissal (including cancellation).
    .moment(
      moment,
      editEnabled: true,
      zoomSource: reduceMotion ? nil : MomentZoomSource(id: moment.uuid, namespace: namespace)
    )
  }

  var body: some View {
    NavigationLink(value: destination) {
      label()
        .matchedTransitionSource(id: moment.uuid, in: namespace)
    }
  }
}

#endif
