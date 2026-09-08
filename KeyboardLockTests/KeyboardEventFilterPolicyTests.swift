import CoreGraphics
import XCTest
@testable import KeyboardLock

final class KeyboardEventFilterPolicyTests: XCTestCase {
    func testBlocksStandardKeyboardEvents() {
        XCTAssertTrue(KeyboardEventFilterPolicy.shouldBlock(type: .keyDown))
        XCTAssertTrue(KeyboardEventFilterPolicy.shouldBlock(type: .keyUp))
        XCTAssertTrue(KeyboardEventFilterPolicy.shouldBlock(type: .flagsChanged))
    }

    func testBlocksMediaAndEjectSystemEvents() {
        let type = KeyboardEventFilterPolicy.systemDefinedEventType

        XCTAssertTrue(
            KeyboardEventFilterPolicy.shouldBlock(type: type, systemDefinedSubtype: 8)
        )
        XCTAssertTrue(
            KeyboardEventFilterPolicy.shouldBlock(type: type, systemDefinedSubtype: 10)
        )
    }

    func testPreservesAuxiliaryMouseAndUnrelatedSystemEvents() {
        let type = KeyboardEventFilterPolicy.systemDefinedEventType

        XCTAssertFalse(
            KeyboardEventFilterPolicy.shouldBlock(type: type, systemDefinedSubtype: 7)
        )
        XCTAssertFalse(
            KeyboardEventFilterPolicy.shouldBlock(type: type, systemDefinedSubtype: nil)
        )
    }

    func testPreservesNonKeyboardEvents() {
        XCTAssertFalse(KeyboardEventFilterPolicy.shouldBlock(type: .leftMouseDown))
        XCTAssertFalse(KeyboardEventFilterPolicy.shouldBlock(type: .mouseMoved))
        XCTAssertFalse(KeyboardEventFilterPolicy.shouldBlock(type: .scrollWheel))
    }
}
