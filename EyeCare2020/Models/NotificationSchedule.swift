import Foundation

struct NotificationSchedule: Equatable {
    static let requestIdentifier = "eye-care-phase-end"

    let identifier: String
    let title: String
    let body: String
    let deadline: Date

    static func make(deadline: Date) -> NotificationSchedule {
        NotificationSchedule(
            identifier: requestIdentifier,
            title: "该让眼睛休息了",
            body: "看向约 6 米外 20 秒。",
            deadline: deadline
        )
    }
}
