import XCTest
@testable import FinderTweaksCore

final class FinderFocusPolicyTests: XCTestCase {
    private let finderPID: pid_t = 100

    func testAcceptsKeyWhenFinderIsFrontmostAndOwnsKeyboardFocus() {
        XCTAssertTrue(
            FinderFocusPolicy.acceptsTweakedKey(
                frontmostBundleIdentifier: AppConstants.finderBundleIdentifier,
                focusedElementOwnerPID: finderPID,
                finderPID: finderPID
            )
        )
    }

    func testRejectsKeyWhenOverlayOwnsKeyboardFocus() {
        XCTAssertFalse(
            FinderFocusPolicy.acceptsTweakedKey(
                frontmostBundleIdentifier: AppConstants.finderBundleIdentifier,
                focusedElementOwnerPID: 200,
                finderPID: finderPID
            )
        )
    }

    func testRejectsKeyWhenFocusOwnerCannotBeDetermined() {
        XCTAssertFalse(
            FinderFocusPolicy.acceptsTweakedKey(
                frontmostBundleIdentifier: AppConstants.finderBundleIdentifier,
                focusedElementOwnerPID: nil,
                finderPID: finderPID
            )
        )
    }

    func testRejectsKeyWhenFinderIsNotFrontmost() {
        XCTAssertFalse(
            FinderFocusPolicy.acceptsTweakedKey(
                frontmostBundleIdentifier: "com.raycast.macos",
                focusedElementOwnerPID: finderPID,
                finderPID: finderPID
            )
        )
    }
}
