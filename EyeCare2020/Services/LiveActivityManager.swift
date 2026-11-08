import ActivityKit
import Foundation
import UIKit

@MainActor
final class LiveActivityManager {
    private var activity: Activity<EyeCareLiveActivityAttributes>?
    private var pendingState: EyeCareLiveActivityAttributes.ContentState?
    private var updateTask: Task<Void, Never>?
    private var lastSubmittedState: EyeCareLiveActivityAttributes.ContentState?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

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
        guard state != lastSubmittedState else { return }
        pendingState = state
        scheduleUpdate()
    }

    private func scheduleUpdate() {
        guard updateTask == nil else { return }

        if UIApplication.shared.applicationState != .active,
           backgroundTask == .invalid {
            backgroundTask = UIApplication.shared.beginBackgroundTask(
                withName: "Update Eye Care Live Activity"
            ) { [weak self] in
                self?.finishBackgroundTask()
            }
        }

        updateTask = Task(priority: .userInitiated) { [weak self] in
            await self?.drainUpdates()
        }
    }

    private func drainUpdates() async {
        while let state = pendingState {
            pendingState = nil
            let content = ActivityContent(
                state: state,
                staleDate: state.deadline ?? Date().addingTimeInterval(3_600)
            )

            if let activity {
                await activity.update(content)
                lastSubmittedState = state
            } else {
                do {
                    activity = try Activity.request(
                        attributes: EyeCareLiveActivityAttributes(title: "远眺"),
                        content: content,
                        pushType: nil
                    )
                    lastSubmittedState = state
                } catch {
                    activity = nil
                }
            }
        }

        updateTask = nil
        if pendingState != nil {
            scheduleUpdate()
        } else {
            finishBackgroundTask()
        }
    }

    func end() {
        pendingState = nil
        lastSubmittedState = nil
        updateTask?.cancel()
        updateTask = nil
        finishBackgroundTask()

        guard let activity else { return }
        self.activity = nil

        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private func finishBackgroundTask() {
        guard backgroundTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
}
