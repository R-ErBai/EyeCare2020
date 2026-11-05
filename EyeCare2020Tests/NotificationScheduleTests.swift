import XCTest
#if canImport(EyeCare2020Core)
@testable import EyeCare2020Core
#else
@testable import EyeCare2020
#endif

final class NotificationScheduleTests: XCTestCase {
    func testWorkDeadlineProducesLookAwayPrompt() {
        let deadline = Date(timeIntervalSince1970: 2_000_000)

        let plan = NotificationSchedule.make(deadline: deadline)

        XCTAssertEqual(plan.identifier, "eye-care-phase-end")
        XCTAssertEqual(plan.title, "该让眼睛休息了")
        XCTAssertEqual(plan.deadline, deadline)
    }
}
