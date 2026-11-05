import SwiftUI
import UserNotifications

@main
@MainActor
struct EyeCare2020App: App {
    @StateObject private var timerViewModel: TimerViewModel
    private let notificationDelegate: AppNotificationDelegate

    init() {
        let delegate = AppNotificationDelegate()
        notificationDelegate = delegate
        _timerViewModel = StateObject(wrappedValue: TimerViewModel())
        UNUserNotificationCenter.current().delegate = delegate
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(timerViewModel)
        }
    }
}

final class AppNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // The in-app phase screen is the foreground prompt; the sound still gets attention.
        completionHandler([.sound])
    }
}
