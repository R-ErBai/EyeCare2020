import XCTest
#if canImport(EyeCare2020Core)
@testable import EyeCare2020Core
#else
@testable import EyeCare2020
#endif

final class NotificationScheduleTests: XCTestCase {
    func testRestNotificationOffersOneMinuteExtension() {
        let deadline = Date(timeIntervalSince1970: 2_000_000)

        let plan = NotificationSchedule.restChoice(deadline: deadline)

        XCTAssertEqual(plan.identifier, "eye-care-rest-choice")
        XCTAssertEqual(plan.categoryIdentifier, "eye-care-rest-choice-category")
        XCTAssertEqual(plan.title, "休息 20 秒已开始")
        XCTAssertEqual(plan.body, "想休息更久，可展开通知改为 1 分钟。")
        XCTAssertEqual(plan.deadline, deadline)
        XCTAssertEqual(plan.actions, [
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
        XCTAssertEqual(plan.sound, .none)
    }

    func testRestEndSoundOptionsExposeFourDistinctBundledFiles() {
        XCTAssertEqual(RestEndSound.allCases.count, 4)
        XCTAssertEqual(Set(RestEndSound.allCases.map(\.fileName)).count, 4)
        XCTAssertEqual(RestEndSound.defaultSound.title, "柔和提示")
    }
}
