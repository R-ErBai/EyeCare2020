import Foundation

enum RestEndSound: String, CaseIterable, Hashable {
    case softChime = "soft-chime"
    case woodblock
    case doubleBell = "double-bell"
    case digitalBeep = "digital-beep"

    static let defaultSound = RestEndSound.softChime

    var title: String {
        switch self {
        case .softChime:
            return "柔和提示"
        case .woodblock:
            return "木鱼"
        case .doubleBell:
            return "双音铃"
        case .digitalBeep:
            return "电子滴声"
        }
    }

    var fileName: String {
        "\(rawValue).wav"
    }
}

struct NotificationActionPlan: Equatable {
    let identifier: String
    let title: String
}

enum NotificationSoundPlan: Equatable {
    case none
    case defaultSound
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
    let sound: NotificationSoundPlan

    static func restChoice(deadline: Date) -> NotificationSchedule {
        NotificationSchedule(
            identifier: restChoiceRequestIdentifier,
            categoryIdentifier: restChoiceCategoryIdentifier,
            title: "该让眼睛休息了",
            body: "展开通知，直接选择休息 20 秒或 1 分钟。",
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
            ],
            sound: .defaultSound
        )
    }

    static func restEnd(deadline: Date) -> NotificationSchedule {
        NotificationSchedule(
            identifier: restEndRequestIdentifier,
            categoryIdentifier: nil,
            title: "休息结束",
            body: "可以继续下一轮用眼了。",
            deadline: deadline,
            actions: [],
            sound: .none
        )
    }
}
