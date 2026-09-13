import CoreGraphics
import XCTest
@testable import FinderTweaksCore

final class KeyMappingTests: XCTestCase {
    func testDefaultMappings() {
        let settings = FinderTweaksSettings()

        XCTAssertEqual(action(FinderKeyCode.returnKey, settings), .openSelectedItems)
        XCTAssertEqual(action(FinderKeyCode.enter, settings), .openSelectedItems)
        XCTAssertEqual(action(FinderKeyCode.f2, settings), .renameSelectedItem)
        XCTAssertEqual(action(FinderKeyCode.delete, settings), .moveSelectedItemsToTrash)
        XCTAssertEqual(action(FinderKeyCode.forwardDelete, settings), .moveSelectedItemsToTrash)
    }

    func testDisabledAppDoesNotMapKeys() {
        var settings = FinderTweaksSettings()
        settings.enabled = false

        XCTAssertNil(action(FinderKeyCode.returnKey, settings))
        XCTAssertNil(action(FinderKeyCode.f2, settings))
        XCTAssertNil(action(FinderKeyCode.delete, settings))
    }

    func testIndividualMappingCanBeDisabled() {
        var settings = FinderTweaksSettings()
        settings.f2RenamesItem = false

        XCTAssertNil(action(FinderKeyCode.f2, settings))
        XCTAssertEqual(action(FinderKeyCode.returnKey, settings), .openSelectedItems)
    }

    func testStandardModifiersPreserveFinderBehavior() {
        let settings = FinderTweaksSettings()

        for flags: CGEventFlags in [.maskShift, .maskControl, .maskAlternate, .maskCommand] {
            XCTAssertNil(action(FinderKeyCode.returnKey, settings, flags: flags))
            XCTAssertNil(action(FinderKeyCode.delete, settings, flags: flags))
            XCTAssertNil(action(FinderKeyCode.f2, settings, flags: flags))
        }
    }

    func testFunctionModifierDoesNotBlockForwardDeleteOrF2() {
        let settings = FinderTweaksSettings()

        XCTAssertEqual(
            action(FinderKeyCode.forwardDelete, settings, flags: .maskSecondaryFn),
            .moveSelectedItemsToTrash
        )
        XCTAssertEqual(
            action(FinderKeyCode.f2, settings, flags: .maskSecondaryFn),
            .renameSelectedItem
        )
    }

    func testUnrelatedKeyIsNotMapped() {
        XCTAssertNil(action(0, FinderTweaksSettings()))
    }

    private func action(
        _ keyCode: CGKeyCode,
        _ settings: FinderTweaksSettings,
        flags: CGEventFlags = []
    ) -> FinderAction? {
        KeyMapping.action(for: keyCode, flags: flags, settings: settings)
    }
}
