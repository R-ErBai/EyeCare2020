import UIKit

final class LockObserver {
    var onLock: (() -> Void)?
    var onUnlock: (() -> Void)?

    private let center: NotificationCenter
    private var tokens: [NSObjectProtocol] = []

    init(center: NotificationCenter = .default) {
        self.center = center

        let lockToken = center.addObserver(
            forName: UIApplication.protectedDataWillBecomeUnavailableNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.onLock?()
        }

        let unlockToken = center.addObserver(
            forName: UIApplication.protectedDataDidBecomeAvailableNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.onUnlock?()
        }

        tokens = [lockToken, unlockToken]
    }

    deinit {
        tokens.forEach(center.removeObserver)
    }
}
