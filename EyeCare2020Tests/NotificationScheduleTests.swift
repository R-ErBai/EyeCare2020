import XCTest
#if canImport(EyeCare2020Core)
@testable import EyeCare2020Core
#else
@testable import EyeCare2020
#endif

final class NotificationScheduleTests: XCTestCase {
    func testRestChoiceNotificationIncludesTwentySecondAndOneMinuteActions() {
        let deadline = Date(timeIntervalSince1970: 2_000_000)

        let plan = NotificationSchedule.restChoice(deadline: deadline)

        XCTAssertEqual(plan.identifier, "eye-care-rest-choice")
        XCTAssertEqual(plan.categoryIdentifier, "eye-care-rest-choice-category")
        XCTAssertEqual(plan.title, "该让眼睛休息了")
        XCTAssertEqual(plan.body, "选择休息 20 秒或 1 分钟。")
        XCTAssertEqual(plan.deadline, deadline)
        XCTAssertEqual(plan.actions, [
            NotificationActionPlan(identifier: "eye-care-rest-20-seconds", title: "休息 20 秒"),
            NotificationActionPlan(identifier: "eye-care-rest-1-minute", title: "休息 1 分钟")
        ])
    }

    func testRestEndNotificationUsesCompletionIdentifierAndText() {
        let deadline = Date(timeIntervalSince1970: 2_000_060)

        let plan = NotificationSchedule.restEnd(deadline: deadline)

        XCTAssertEqual(plan.identifier, "eye-care-rest-end")
        XCTAssertEqual(plan.categoryIdentifier, nil)
        XCTAssertEqual(plan.title, "休息结束")
        XCTAssertEqual(plan.body, "可以继续下一轮用眼了。")
        XCTAssertEqual(plan.deadline, deadline)
        XCTAssertTrue(plan.actions.isEmpty)
    }
}
