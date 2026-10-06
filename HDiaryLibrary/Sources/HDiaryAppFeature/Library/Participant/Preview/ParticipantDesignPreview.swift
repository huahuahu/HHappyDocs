#if DEBUG && os(iOS)
  import SwiftUI

  /// Design exploration only. All edits stay in this preview's value-type sample data.
  /// Retained alternatives; AllParticipantsPreview renders the selected design in the real page.
  private struct ParticipantDesignPreview: View {
    let design: ParticipantPreviewDesign
    var people = ParticipantPreviewPerson.samples

    @State private var selection = HDiaryTab.library
    @State private var path: [ParticipantPreviewRoute] = [.participants]

    var body: some View {
      TabView(selection: $selection) {
        Tab(value: HDiaryTab.content) {
          Color.clear
        } label: {
          Label {
            Text(verbatim: "乐事")
          } icon: {
            Image(systemName: "list.dash")
          }
        }

        Tab(value: HDiaryTab.library) {
          NavigationStack(path: $path) {
            List {
              NavigationLink(value: ParticipantPreviewRoute.participants) {
                Text(verbatim: "参与者")
              }
            }
            .navigationTitle(Text(verbatim: "资料库"))
            .navigationDestination(for: ParticipantPreviewRoute.self) { _ in
              ParticipantDesignScreen(design: design, people: people)
            }
          }
        } label: {
          Label {
            Text(verbatim: "资料库")
          } icon: {
            Image(systemName: "cube.box")
          }
        }

        Tab(value: HDiaryTab.setting) {
          Color.clear
        } label: {
          Label {
            Text(verbatim: "设置")
          } icon: {
            Image(systemName: "gear")
          }
        }
      }
      .tint(.orange)
      .environment(\.locale, Locale(identifier: "zh_CN"))
    }
  }

  private enum ParticipantPreviewRoute: Hashable {
    case participants
  }

  private struct ParticipantDesignScreen: View {
    let design: ParticipantPreviewDesign
    @State private var people: [ParticipantPreviewPerson]
    @State private var editingPerson: ParticipantPreviewPerson?

    init(design: ParticipantPreviewDesign, people: [ParticipantPreviewPerson]) {
      self.design = design
      self.people = people
    }

    var body: some View {
      ParticipantDesignCollection(design: design, people: people) { person in
        editingPerson = person
      }
      .navigationTitle(Text(verbatim: "参与者"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button {
            editingPerson = ParticipantPreviewPerson(id: UUID().uuidString, name: "")
          } label: {
            Text(verbatim: "添加")
          }
        }
      }
      .sheet(item: $editingPerson) { person in
        ParticipantDesignEditor(person: person) { updatedPerson in
          if let index = people.firstIndex(where: { $0.id == updatedPerson.id }) {
            people[index] = updatedPerson
          }
          else {
            people.append(updatedPerson)
          }
        }
      }
    }
  }

  private struct ParticipantDesignEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var person: ParticipantPreviewPerson
    let save: (ParticipantPreviewPerson) -> Void

    init(person: ParticipantPreviewPerson, save: @escaping (ParticipantPreviewPerson) -> Void) {
      self.person = person
      self.save = save
    }

    var body: some View {
      NavigationStack {
        Form {
          Section {
            HStack {
              Spacer()
              ParticipantDesignAvatar(name: person.name, symbol: person.symbol, size: 76)
              Spacer()
            }
            .listRowBackground(Color.clear)
          }
          Section {
            TextField(text: $person.name) {
              Text(verbatim: "昵称")
            }
          }
        }
        .navigationTitle(Text(verbatim: "参与者"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button { dismiss() } label: { Text(verbatim: "取消") }
          }
          ToolbarItem(placement: .confirmationAction) {
            Button {
              person.name = person.name.trimmingCharacters(in: .whitespacesAndNewlines)
              save(person)
              dismiss()
            } label: {
              Text(verbatim: "完成")
            }
            .disabled(person.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
          }
        }
      }
    }
  }

  #Preview("A · 柔和头像网格", traits: .fixedLayout(width: 402, height: 874)) {
    ParticipantDesignPreview(design: .avatarGrid)
  }

  #Preview("B · 紧凑双列名片", traits: .fixedLayout(width: 402, height: 874)) {
    ParticipantDesignPreview(design: .compactCards)
  }

  #Preview("C · 大头像卡片", traits: .fixedLayout(width: 402, height: 874)) {
    ParticipantDesignPreview(design: .portraitCards)
  }

  #Preview("D · 原生列表", traits: .fixedLayout(width: 402, height: 874)) {
    ParticipantDesignPreview(design: .nativeList)
  }

  #Preview("A · 深色模式", traits: .fixedLayout(width: 402, height: 874)) {
    ParticipantDesignPreview(design: .avatarGrid)
      .preferredColorScheme(.dark)
  }

  #Preview("A · 长名字与大字号", traits: .fixedLayout(width: 402, height: 874)) {
    ParticipantDesignPreview(design: .avatarGrid, people: ParticipantPreviewPerson.longNames)
      .environment(\.dynamicTypeSize, .accessibility3)
  }
#endif
