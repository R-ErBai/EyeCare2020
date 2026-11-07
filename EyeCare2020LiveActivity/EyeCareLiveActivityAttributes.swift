import ActivityKit
import Foundation

enum EyeCareActivityPhase: String, Codable, Hashable {
    case work
    case lookAway
    case restChoice
}

enum EyeCareActivityStatus: String, Codable, Hashable {
    case running
    case waiting
    case paused
}

struct EyeCareLiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let phase: EyeCareActivityPhase
        let status: EyeCareActivityStatus
        let deadline: Date?
        let remaining: TimeInterval
        let workMinutes: Int
    }

    let title: String
}
