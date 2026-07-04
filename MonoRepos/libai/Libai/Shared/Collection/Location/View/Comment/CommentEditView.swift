////
////  CommentEditView.swift
////  Libai (iOS)
////
////  Created by huahuahu on 2022/4/10.
////
//
// import AlertToast
// import SwiftUI
//
// struct CommentEditView: View {
//  internal init(locationID: String, isPresenting: Binding<Bool>,
//                onSaveSuccess: @escaping () -> Void)
//  {
//    self.locationID = locationID
//    _isPresenting = isPresenting
//    self.onSaveSuccess = onSaveSuccess
//  }
//
//  @Binding private var isPresenting: Bool
//  @State private var errorMessge: String?
//  @State private var content: String = ""
//  @FocusState private var focusedField: Field?
//  private let locationID: String
//  private let onSaveSuccess: () -> Void
//
//  enum Field: Hashable {
//    case text
//  }
//
//  private func saveToPersonal(_ comment: LocationComment) throws {
//    let personalComment = CDLocationComment(context: HCoreDataStack.shared.privateManagedContext)
//    personalComment.id = comment.id
//    personalComment.locationUniqueName = comment.locationUniqueName
//    personalComment.content = comment.content
//    personalComment.date = comment.date
//    try HCoreDataStack.shared.privateManagedContext.save()
//  }
//
//  var body: some View {
//    NavigationView {
//      TextEditor(text: $content)
//        .foregroundColor(.primary)
//        .padding(.horizontal)
//        .focused($focusedField, equals: .text)
//
//        .navigationTitle(PredefinedString.comments)
//        .onAppear {
//          Task {
//            try? await Task.sleep(nanoseconds: 1_000_000_000)
//            focusedField = .text
//          }
//        }
//        .onDisappear {
//          focusedField = nil
//        }
//        .navigationBarTitleDisplayMode(.inline)
//        .toolbar {
//          ToolbarItemGroup(placement: .confirmationAction) {
//            AsyncButton {
//              var saveSuccess = false
//              hLog("save", scenerio: .ui)
//              let comment = LocationComment(
//                content: content,
//                userid: ICloudConstants.userID,
//                locationUniqueName: locationID,
//                id: UUID().uuidString,
//                date: Date.now
//              )
//              defer {
//                if saveSuccess {
//                  do {
//                    try HCoreDataStack.shared.saveLocalIfNeed()
//                    try saveToPersonal(comment)
//                  } catch {
//                    hLog("save core data fail", scenerio: .ui)
//                  }
//                  isPresenting = false
//                  onSaveSuccess()
//                }
//              }
//              do {
//                try await LocationCommentSaver().save(comment)
//                dataLog("save finish \(comment)")
//                saveSuccess = true
//              } catch {
//                focusedField = nil
//                if let iCloudError = error as? ICloudError {
//                  errorMessge = PredefinedString.loginICloudRequired
//
//                  switch iCloudError {
//                  case let .checkAccountStatusError(error):
//                    dataLog("icloud checkAccountStatusError \(error)")
//                  case let .accountAbnormal(status):
//                    dataLog("icloud accountAbnormal \(status)")
//                  }
//                } else {
//                  errorMessge = nil
//                }
//                hLog("save fail \(error)", scenerio: .ui)
//              }
//            } label: {
//              Text(PredefinedString.submit)
//            }
//            .disabled(content.isEmpty)
//          }
//        }
//        .toast(
//          isPresenting: .init(get: {
//            errorMessge != nil
//          }, set: { newVaule in
//            if !newVaule {
//              errorMessge = nil
//            }
//          }),
//          duration: 2,
//          tapToDismiss: true,
//          offsetY: 0,
//          alert: {
//            AlertToast(displayMode: .alert, type: .error(.red), title: errorMessge)
//          }, onTap: {
//            focusedField = .text
//          }, completion: {
////                errorMessge = nil
//          }
//        )
//    }
//  }
// }
//
// struct CommentEditView_Previews: PreviewProvider {
//  static var previews: some View {
//    CommentEditView(locationID: "test", isPresenting: .constant(true)) {
//      //
//    }
//  }
// }
