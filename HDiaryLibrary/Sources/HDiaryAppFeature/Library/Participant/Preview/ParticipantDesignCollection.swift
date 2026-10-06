#if DEBUG && os(iOS)
  import SwiftUI

  enum ParticipantPreviewDesign {
    case avatarGrid
    case compactCards
    case portraitCards
    case nativeList
  }

  struct ParticipantPreviewPerson: Identifiable {
    let id: String
    var name: String
    var symbol: String?

    static let samples: [Self] = [
      .init(id: "baby", name: "宝宝"),
      .init(id: "feifei", name: "菲菲", symbol: "heart.fill"),
      .init(id: "junjun", name: "俊俊"),
      .init(id: "tingting", name: "婷婷"),
      .init(id: "xiaohan", name: "小涵"),
      .init(id: "xiaoyu", name: "小雨", symbol: "leaf.fill"),
      .init(id: "xinxin", name: "心心", symbol: "paperplane.fill"),
      .init(id: "sunshine", name: "阳光"),
      .init(id: "yubao", name: "宇宝"),
      .init(id: "yuge", name: "宇哥"),
    ]

    static let longNames: [Self] = [
      .init(id: "family", name: "一起记录生活的家人"),
      .init(id: "friend", name: "Alexandra Chen", symbol: "heart.fill"),
      .init(id: "baby", name: "宝宝"),
      .init(id: "rain", name: "小雨 🌿", symbol: "leaf.fill"),
    ]
  }

  struct ParticipantDesignCollection: View {
    let design: ParticipantPreviewDesign
    let people: [ParticipantPreviewPerson]
    let select: (ParticipantPreviewPerson) -> Void

    var body: some View {
      ZStack {
        switch design {
        case .avatarGrid:
          ParticipantAvatarGrid(people: people, select: select)
        case .compactCards:
          ParticipantCardGrid(people: people, portrait: false, select: select)
        case .portraitCards:
          ParticipantCardGrid(people: people, portrait: true, select: select)
        case .nativeList:
          ParticipantNativeList(people: people, select: select)
        }
      }
    }
  }

  private struct ParticipantPreviewCount: View {
    let count: Int

    var body: some View {
      Text(verbatim: "\(count) 位参与者")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityAddTraits(.isHeader)
    }
  }

  private struct ParticipantAvatarGrid: View {
    let people: [ParticipantPreviewPerson]
    let select: (ParticipantPreviewPerson) -> Void
    @ScaledMetric(relativeTo: .body) private var cellWidth = 72.0
    @ScaledMetric(relativeTo: .body) private var avatarSize = 64.0

    var body: some View {
      ScrollView {
        VStack(alignment: .leading, spacing: 28) {
          ParticipantPreviewCount(count: people.count)
          LazyVGrid(columns: [GridItem(.adaptive(minimum: cellWidth), spacing: 12)], spacing: 28) {
            ForEach(people) { person in
              Button {
                select(person)
              } label: {
                VStack(spacing: 10) {
                  ParticipantDesignAvatar(name: person.name, symbol: person.symbol, size: avatarSize)
                  Text(person.name)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .contentShape(Rectangle())
              }
              .buttonStyle(.plain)
              .accessibilityLabel(person.name)
            }
          }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 24)
      }
      .background(.background)
    }
  }

  private struct ParticipantCardGrid: View {
    let people: [ParticipantPreviewPerson]
    let portrait: Bool
    let select: (ParticipantPreviewPerson) -> Void
    @ScaledMetric(relativeTo: .body) private var minimumWidth = 155.0

    var body: some View {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          ParticipantPreviewCount(count: people.count)
          LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumWidth), spacing: 12)], spacing: 12) {
            ForEach(people) { person in
              Button {
                select(person)
              } label: {
                ParticipantPreviewCard(person: person, portrait: portrait)
              }
              .buttonStyle(.plain)
              .accessibilityLabel(person.name)
            }
          }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 24)
      }
      .background(Color(uiColor: .systemGroupedBackground))
    }
  }

  private struct ParticipantPreviewCard: View {
    let person: ParticipantPreviewPerson
    let portrait: Bool
    @ScaledMetric(relativeTo: .body) private var compactAvatarSize = 42.0
    @ScaledMetric(relativeTo: .body) private var portraitAvatarSize = 72.0

    var body: some View {
      VStack {
        if portrait {
          VStack(spacing: 16) {
            ParticipantDesignAvatar(
              name: person.name, symbol: person.symbol, size: portraitAvatarSize, roundedSquare: true
            )
            Text(person.name)
              .font(.body.weight(.medium))
              .multilineTextAlignment(.center)
          }
          .padding(.vertical, 24)
          .padding(.horizontal, 12)
        }
        else {
          HStack(spacing: 12) {
            ParticipantDesignAvatar(name: person.name, symbol: person.symbol, size: compactAvatarSize)
            Text(person.name)
              .font(.body)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          .padding(16)
        }
      }
      .foregroundStyle(.primary)
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 22))
      .contentShape(.rect(cornerRadius: 22))
    }
  }

  private struct ParticipantNativeList: View {
    let people: [ParticipantPreviewPerson]
    let select: (ParticipantPreviewPerson) -> Void
    @ScaledMetric(relativeTo: .body) private var avatarSize = 42.0

    var body: some View {
      List {
        Section {
          ForEach(people) { person in
            Button {
              select(person)
            } label: {
              HStack(spacing: 14) {
                ParticipantDesignAvatar(name: person.name, symbol: person.symbol, size: avatarSize)
                Text(person.name)
                  .font(.body)
                  .foregroundStyle(.primary)
                  .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                  .font(.caption.weight(.semibold))
                  .foregroundStyle(.tertiary)
                  .accessibilityHidden(true)
              }
              .padding(.vertical, 5)
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(person.name)
          }
        } header: {
          ParticipantPreviewCount(count: people.count)
        }
      }
      .listStyle(.insetGrouped)
    }
  }

  struct ParticipantDesignAvatar: View {
    let name: String
    let symbol: String?
    let size: CGFloat
    var roundedSquare = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
      ZStack {
        RoundedRectangle(cornerRadius: roundedSquare ? size * 0.28 : size / 2)
          .fill(Color.orange.opacity(colorScheme == .dark ? 0.17 : 0.1))
        if let symbol {
          Image(systemName: symbol)
            .font(.system(size: size * 0.4, weight: .medium))
        }
        else {
          Text(String(name.trimmingCharacters(in: .whitespacesAndNewlines).first ?? "人"))
            .font(.system(size: size * 0.38, weight: .medium, design: .rounded))
        }
      }
      .foregroundStyle(colorScheme == .dark ? Color.orange : Color.brown)
      .frame(width: size, height: size)
      .accessibilityHidden(true)
    }
  }
#endif
