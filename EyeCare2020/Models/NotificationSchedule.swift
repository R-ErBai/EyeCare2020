import Foundation

struct NotificationActionPlan: Equatable {
    let identifier: String
    let title: String
}

struct NotificationSchedule: Equatable {
    static let restChoiceRequestIdentifier = "eye-care-rest-choice"
    static let restEndRequestIdentifier = "eye-care-rest-end"
    static let legacyRequestIdentifier = "eye-care-phase-end"
    static let restChoiceCategoryIdentifier = "eye-care-rest-choice-category"
    static let restTwentySecondsActionIdentifier = "eye-care-rest-20-seconds"
    static let restOneMinuteActionIdentifier = "eye-care-rest-1-minute"

    let identifier: String
    let categoryIdentifier: String?
    let title: String
    let body: String
    let deadline: Date
    let actions: [NotificationActionPlan]

    static func restChoice(deadline: Date) -> NotificationSchedule {
        NotificationSchedule(
            identifier: restChoiceRequestIdentifier,
            categoryIdentifier: restChoiceCategoryIdentifier,
            title: "该让眼睛休息了",
            body: "选择休息 20 秒或 1 分钟。",
            deadline: deadline,
            actions: [
                NotificationActionPlan(
                    identifier: restTwentySecondsActionIdentifier,
                    title: "休息 20 秒"
                ),
                NotificationActionPlan(
                    identifier: restOneMinuteActionIdentifier,
                    title: "休息 1 分钟"
                )
            ]
        )
    }

    static func restEnd(deadline: Date) -> NotificationSchedule {
        NotificationSchedule(
            identifier: restEndRequestIdentifier,
            categoryIdentifier: nil,
            title: "休息结束",
            body: "可以继续下一轮用眼了。",
            deadline: deadline,
            actions: []
        )
    }
}
