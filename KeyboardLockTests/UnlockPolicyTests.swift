import XCTest
@testable import KeyboardLock

final class UnlockPolicyTests: XCTestCase {
    func testFallbackHoldRequiresTenSeconds() {
        XCTAssertEqual(UnlockPolicy.holdDuration, 10)
        XCTAssertEqual(UnlockPolicy.holdDurationSeconds, 10)
    }
}
