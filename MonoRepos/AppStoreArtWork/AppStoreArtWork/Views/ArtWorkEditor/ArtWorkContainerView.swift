//
//  ArtWorkContainerView.swift
//  AppStoreArtWork
//
//  Created by tigerguo on 2025/3/19.
//

import SwiftUI

struct ArtWorkContainerView: View {
  let target: Target
  @State private var scale: Double = 0.3
  @State private var showInspector = false // 新增inspector状态
  @Environment(Store.self) private var store: Store
  @State private var selectedModel: ArtWorkModel? // 新增选中的model

//    var art
  var body: some View {
    ScrollView([.horizontal, .vertical]) {
      HStack(spacing: 20) {
        ForEach(store.models[target] ?? []) { model in
          artWorkViewWithBorderState(model)
            .onTapGesture {
              selectedModel = model
            }
        }

        addModelView
          .frame(
            width: target.size.width * scale * 0.5,
            height: target.size.height * scale * 0.5
          )
      }
      .padding(.horizontal)
    }
    .scrollBounceBehavior(.always)
    .toolbar {
      ToolbarItemGroup(placement: .automatic) {
        Slider(value: $scale, in: 0 ... 1)
          .frame(width: 100)

        Button {
          showInspector.toggle() // 切换显示状态
        } label: {
          Image(systemName: "sidebar.leading")
        }
      }
    }

    .inspector(isPresented: $showInspector) {
      if let model = selectedModel {
        ArtWorkModelInfoView(scale: scale, model: model, target: target)
      }
      else {
        ContentUnavailableView {
          Text(verbatim: "请选择一个模型")
        }
      }
    }
    .task(id: target) {
      selectedModel = nil
    }
  }

  private var addModelView: some View {
    ZStack {
      Color.gray.opacity(0.2)
      Button {
        store.add(ArtWorkModel.getEmptyModel(), to: target)
      } label: {
        Label {
          Text(verbatim: "添加")
        } icon: {
          Image(systemName: "plus")
        }
        .padding(.all, 30 * scale)
      }
      .buttonStyle(.borderedProminent)
      .font(.system(size: 72 * scale))
    }
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(.blue.opacity(0.2), lineWidth: 4)
    )
  }

  @ViewBuilder
  private func artWorkViewWithBorderState(_ model: ArtWorkModel) -> some View {
    ZStack {
      if model.id == selectedModel?.id {
        RoundedRectangle(cornerRadius: 20)
          .stroke(Color.blue, lineWidth: 3) // 设置边框颜色和线宽
          .frame(
            width: target.size.width * scale * 1.05,
            height: target.size.height * scale * 1.05
          ) // 设置尺寸
          .background(Color.clear) // 保持中心透明
      }
      ArtWorkView(target: target, scale: scale, model: model) // 添加scale参数
        .frame(
          width: target.size.width * scale,
          height: target.size.height * scale
        )
    }
    .frame(
      width: target.size.width * scale * 1.05,
      height: target.size.height * scale * 1.05
    )
    .overlay(alignment: .topLeading) {
      if model.id == selectedModel?.id {
        // remove button
        Button {
          store.remove(model, from: target)
        } label: {
          Label {
            Text(verbatim: "remove")
          } icon: {
            Image(systemName: "minus")
              .symbolVariant(.circle)
          }
          .font(.system(size: 30))
          .labelStyle(.iconOnly)
        }
        .buttonBorderShape(.circle)
        .buttonStyle(.borderedProminent)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(.circle)
      }
      else {
        EmptyView()
      }
    }
  }
}

#Preview {
  NavigationSplitView {
    Text(verbatim: "Hello, ArtWork!")
  } detail: {
    ArtWorkContainerView(target: .sixFiveInch)
  }
  .environment(Store())
}
