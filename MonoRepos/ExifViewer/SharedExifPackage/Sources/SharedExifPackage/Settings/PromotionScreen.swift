import SwiftUI

@MainActor
struct PromotionScreen: View {
  @Environment(\.openURL) private var openURL
  @Environment(\.dismiss) private var dismiss

  @ScaledMetric private var unlockImageSize: CGFloat = 60
  @ScaledMetric private var unlockButtonCornerRadius: CGFloat = 8
  @ScaledMetric private var vStackSpacing: CGFloat = 24

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: vStackSpacing) {
          Image(hExifSymbol: .promote)
            .font(.system(size: unlockImageSize))
            .foregroundStyle(Color(AppConstant.proAppTintColor))

          Text(ExifString.Promotion.unlockProTitle.hDocLocalized())
            .font(.largeTitle)
            .fontWeight(.bold)

          Text(ExifString.Promotion.enjoyMoreFeatures.hDocLocalized())
            .multilineTextAlignment(.center)

          Button {
            if let url = URL(string: "itms-apps://apple.com/app/id1234567890") {
              openURL(url)
            }
          } label: {
            Text(ExifString.Promotion.getProButton.hDocLocalized())
              .padding()
              .foregroundColor(.white)
              .background(Color(AppConstant.proAppTintColor))
              .cornerRadius(unlockButtonCornerRadius)
          }
          .padding(.top)
        }
        .padding()
      }
      .scrollIndicators(.hidden)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: { dismiss() }) {
            Label {
              Text(ExifString.Common.close.hDocLocalized())
            } icon: {
              Image(hExifSymbol: .remove)
                .symbolVariant(.circle.fill)
                .font(.title2)
            }
            .labelStyle(.iconOnly)
          }
          .tint(Color(AppConstant.proAppTintColor))
        }
      }
    }
  }
}

#Preview { @MainActor in
  PromotionScreen()
}
