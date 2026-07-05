//
//  Section.swift
//  HDiary
//
//  Created by tigerguo on 2024/1/28.
//

import HDiaryModel
import SwiftData
import SwiftUI

@MainActor
extension MomentListScreen {
  struct SectionView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext

    @State private var isExpanded = false
    let momentGroup: InstanceGroup<Moment>

    var body: some View {
      DisclosureGroup(
        isExpanded: $isExpanded,
        content: {
          ForEach(momentGroup.instances) { moment in
            NavigationLink(value: HDiaryDestination.moment(moment, editEnabled: true)) {
              MomentListItemView(moment: moment)
            }
          }
          .onDelete(perform: { indexSet in
            let momentsToRemove = indexSet.map { momentGroup.instances[$0] }
            withAnimation {
              for moment in momentsToRemove {
                moment.markAsDelete()
//                modelContext.delete(moment)
              }
            }
            try? modelContext.save()
          })

        },
        label: {
          summaryView
        }
      )
    }

    private var summaryView: some View {
      HStack {
        MomentGroupIdView(groupID: momentGroup.identifier)
        Spacer()
        Text(momentGroup.instances.count.formatted())
          .foregroundStyle(.secondary)
      }
    }
  }
}

#if DEBUG
  @MainActor
  private struct PreviewContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor<Moment>(\.timestamp, order: .reverse)]) private var moments: [Moment]

    var body: some View {
      List {
        ForEach(InstanceGrouper().group(moments, relative: .now)) { momentGroup in
          MomentListScreen.SectionView(momentGroup: momentGroup)
        }
      }
    }
  }

  #Preview { @MainActor in

    NavigationStack {
      PreviewContainerView()
        .previewEnvironment()
        .modelContainer(HDiaryContainer.inMemoryPreviewContainer)
    }
  }

#endif
