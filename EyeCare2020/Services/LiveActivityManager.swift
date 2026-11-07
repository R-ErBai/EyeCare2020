import ActivityKit
import Foundation

@MainActor
final class LiveActivityManager {
    private var activity: Activity<EyeCareLiveActivityAttributes>?

    init() {
        activity = Activity<EyeCareLiveActivityAttributes>.activities.first
    }

    func update(
        phase: EyeCareActivityPhase,
        status: EyeCareActivityStatus,
        deadline: Date?,
        remaining: TimeInterval,
        workMinutes: Int
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let state = EyeCareLiveActivityAttributes.ContentState(
            phase: phase,
            status: status,
            deadline: deadline,
            remaining: max(0, remaining),
            workMinutes: workMinutes
        )
        let content = ActivityContent(
            state: state,
            staleDate: deadline ?? Date().addingTimeInterval(3_600)
        )

        if let activity {
            Task {
                await activity.update(content)
            }
            return
        }

        do {
            activity = try Activity.request(
                attributes: EyeCareLiveActivityAttributes(title: "远眺"),
                content: content,
                pushType: nil
            )
        } catch {
            activity = nil
        }
    }

    func end() {
        guard let activity else { return }
        self.activity = nil

        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
