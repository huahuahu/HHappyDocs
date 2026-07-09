#if os(iOS)

  import HDiaryConstants
  import HDiaryModel
  import HDiaryWidgetIntents
  import XCTest

  final class MomentWidgetIntentTests: XCTestCase {
    @MainActor func testWidgetIntentsDeclaresAppIntentsPackage() {
      _ = HDiaryWidgetIntentsAppIntentsPackage()
    }

    func testSelectedParticipantIDUsesStoredUUIDString() {
      let participantID = UUID(uuidString: "9D3C891B-537F-4935-9D21-B763792E49D5").unsafelyUnwrapped

      let intent = MomentWidgetIntent(participantID: participantID.uuidString)

      XCTAssertEqual(intent.participantID, participantID.uuidString)
      XCTAssertEqual(intent.selectedParticipantID, participantID)
    }

    func testSelectedParticipantIDIsNilForInvalidStoredString() {
      let intent = MomentWidgetIntent(participantID: "not-a-uuid")

      XCTAssertEqual(intent.participantID, "not-a-uuid")
      XCTAssertNil(intent.selectedParticipantID)
    }

    func testSelectedParticipantIDSupportsAllParticipantsSentinelString() {
      let intent = MomentWidgetIntent(participantID: UUID.null.uuidString)

      XCTAssertEqual(intent.participantID, UUID.null.uuidString)
      XCTAssertEqual(intent.selectedParticipantID, .null)
    }

    @MainActor func testMomentWidgetModelContextUsesCurrentAppContainer() async {
      let originalContainerType = UserPreferences.shared.swiftDataContainerType
      defer {
        UserPreferences.shared.swiftDataContainerType = originalContainerType
      }
      UserPreferences.shared.swiftDataContainerType = .inMemory

      let context = await MomentWidgetUtil.getModelContext()

      XCTAssertTrue(context.container === HDiaryContainer.getCurrentContainer())
    }
  }

#endif
