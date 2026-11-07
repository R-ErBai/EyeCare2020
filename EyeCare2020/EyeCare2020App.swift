import SwiftUI
import UserNotifications

@main
@MainActor
struct EyeCare2020App: App {
    @StateObject private var timerViewModel: TimerViewModel
    private let notificationDelegate: AppNotificationDelegate

    init() {
        let timerViewModel = TimerViewModel()
        let delegate = AppNotificationDelegate()
        delegate.onNotificationAction = { [weak timerViewModel] identifier in
            Task { @MainActor in
                timerViewModel?.handleNotificationAction(identifier: identifier)
            }
        }
        delegate.onNotificationOpen = { [weak timerViewModel] requestIdentifier in
            Task { @MainActor in
                timerViewModel?.handleNotificationOpen(
                    requestIdentifier: requestIdentifier
                )
            }
        }

        notificationDelegate = delegate
        _timerViewModel = StateObject(wrappedValue: timerViewModel)
        UNUserNotificationCenter.current().delegate = delegate
        NotificationScheduler().registerCategories()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(timerViewModel)
        }
    }
}

final class AppNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    var onNotificationAction: ((String) -> Void)?
    var onNotificationOpen: ((String) -> Void)?

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if notification.request.identifier == NotificationSchedule.restEndRequestIdentifier {
            // The timer plays the selected sound itself to avoid a double sound.
            completionHandler([.banner])
        } else {
            // The in-app choice panel avoids a duplicate banner in the foreground.
            completionHandler([.sound])
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        switch response.actionIdentifier {
        case NotificationSchedule.restTwentySecondsActionIdentifier:
            onNotificationAction?(response.actionIdentifier)
        case NotificationSchedule.restOneMinuteActionIdentifier:
            onNotificationAction?(response.actionIdentifier)
        case UNNotificationDefaultActionIdentifier:
            onNotificationOpen?(response.notification.request.identifier)
        default:
            break
        }

        completionHandler()
    }
}
