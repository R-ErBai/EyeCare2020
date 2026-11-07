import Foundation
import UserNotifications

final class NotificationScheduler {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func registerCategories() {
        let actions = NotificationSchedule.restChoice(deadline: .now).actions.map {
            UNNotificationAction(
                identifier: $0.identifier,
                title: $0.title,
                options: []
            )
        }

        let category = UNNotificationCategory(
            identifier: NotificationSchedule.restChoiceCategoryIdentifier,
            actions: actions,
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([category])
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    func authorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    func schedule(_ plan: NotificationSchedule) {
        let timeInterval = plan.deadline.timeIntervalSinceNow
        guard timeInterval >= 1 else { return }

        let content = UNMutableNotificationContent()
        content.title = plan.title
        content.body = plan.body
        switch plan.sound {
        case .defaultSound:
            content.sound = .default
        case .none:
            break
        }
        if let categoryIdentifier = plan.categoryIdentifier {
            content.categoryIdentifier = categoryIdentifier
        }

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: plan.identifier,
            content: content,
            trigger: trigger
        )

        center.removePendingNotificationRequests(withIdentifiers: [plan.identifier])
        center.add(request, withCompletionHandler: nil)
    }

    func cancelAll() {
        let identifiers = [
            NotificationSchedule.restChoiceRequestIdentifier,
            NotificationSchedule.restEndRequestIdentifier,
            NotificationSchedule.legacyRequestIdentifier
        ]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
}
