import Combine
import Foundation
import UIKit

@MainActor
final class TimerViewModel: ObservableObject {
    @Published private(set) var phase: TimerCore.Phase = .work
    @Published private(set) var status: TimerCore.Status = .idle
    @Published private(set) var remaining: TimeInterval = TimerCore.workDuration
    @Published private(set) var progress: Double = 0
    @Published private(set) var completedWorkCycles = 0
    @Published private(set) var notice: String?

    private var core = TimerCore()
    private var ticker: AnyCancellable?
    private var permissionRequested = false

    private let dateProvider: () -> Date
    private let notificationScheduler: NotificationScheduler
    private let backgroundAudioKeeper: BackgroundAudioKeeper
    private let lockObserver: LockObserver
    private let haptic = UINotificationFeedbackGenerator()

    init(
        dateProvider: @escaping () -> Date = Date.init,
        notificationScheduler: NotificationScheduler = NotificationScheduler(),
        backgroundAudioKeeper: BackgroundAudioKeeper = BackgroundAudioKeeper(),
        lockObserver: LockObserver = LockObserver()
    ) {
        self.dateProvider = dateProvider
        self.notificationScheduler = notificationScheduler
        self.backgroundAudioKeeper = backgroundAudioKeeper
        self.lockObserver = lockObserver

        lockObserver.onLock = { [weak self] in
            Task { @MainActor in
                self?.handleLock()
            }
        }
        lockObserver.onUnlock = { [weak self] in
            Task { @MainActor in
                self?.handleUnlock()
            }
        }
        backgroundAudioKeeper.onFailure = { [weak self] message in
            Task { @MainActor in
                self?.notice = message
            }
        }

        sync(at: dateProvider())
    }

    var isRunning: Bool {
        status != .idle
    }

    var timeText: String {
        let totalSeconds = max(0, Int(ceil(remaining)))
        return String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    var phaseTitle: String {
        switch status {
        case .idle:
            return "准备开始"
        case .locked:
            return "屏幕已锁定"
        case .running:
            return phase == .work ? "用眼计时" : "看向远处"
        }
    }

    var phaseSubtitle: String {
        switch status {
        case .idle:
            return "每 20 分钟，让眼睛休息 20 秒"
        case .locked:
            return "计时已暂停，解锁后会自动处理"
        case .running:
            return phase == .work
                ? "保持工作节奏，到点会提醒你"
                : "看向约 6 米外，放松眼睛"
        }
    }

    var buttonTitle: String {
        isRunning ? "结束计时" : "开始护眼"
    }

    var timerAccessibilityValue: String {
        let totalSeconds = max(0, Int(ceil(remaining)))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes) 分 \(seconds) 秒"
    }

    func toggle() {
        isRunning ? stop() : start()
    }

    func start() {
        let now = dateProvider()
        core.start(at: now)
        guard core.status == .running else { return }

        notice = nil
        sync(at: now)
        startTicker()
        backgroundAudioKeeper.start()
        requestPermissionAndSchedule()
    }

    func stop() {
        let now = dateProvider()
        core.stop(at: now)
        ticker?.cancel()
        ticker = nil
        backgroundAudioKeeper.stop()
        notificationScheduler.cancelAll()
        notice = nil
        sync(at: now)
    }

    func handleTick(_ now: Date) {
        if let event = core.tick(at: now) {
            switch event {
            case .phaseChanged(.lookAway):
                haptic.notificationOccurred(.success)

            case .phaseChanged(.work):
                break
            }

            scheduleCurrentDeadline(at: now)
        }

        sync(at: now)
    }

    private func startTicker() {
        ticker?.cancel()
        ticker = Timer.publish(every: 0.25, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.handleTick(date)
            }
    }

    private func sync(at date: Date) {
        phase = core.phase
        status = core.status
        remaining = core.remaining(at: date)
        progress = core.progress(at: date)
        completedWorkCycles = core.completedWorkCycles
    }

    private func handleLock() {
        let now = dateProvider()
        guard core.lock(at: now) else { return }

        ticker?.cancel()
        ticker = nil
        notificationScheduler.cancelAll()
        sync(at: now)
    }

    private func handleUnlock() {
        let now = dateProvider()
        let result = core.unlock(at: now)

        switch result {
        case .ignored:
            return

        case .resumed:
            notice = "已接着刚才的进度计时"

        case .reset:
            notice = "离开超过 1 分钟，已重新开始 20 分钟"
        }

        startTicker()
        sync(at: now)
        scheduleCurrentDeadline(at: now)
    }

    private func requestPermissionAndSchedule() {
        guard !permissionRequested else {
            scheduleCurrentDeadline(at: dateProvider())
            return
        }

        permissionRequested = true
        notificationScheduler.requestAuthorization { [weak self] granted in
            Task { @MainActor in
                guard let self else { return }

                if granted {
                    self.scheduleCurrentDeadline(at: self.dateProvider())
                } else {
                    self.notice = "通知权限未开启，后台到点时可能没有声音提醒。"
                }
            }
        }
    }

    private func scheduleCurrentDeadline(at date: Date) {
        guard core.status == .running, core.phase == .work else {
            notificationScheduler.cancelAll()
            return
        }

        let deadline = date.addingTimeInterval(core.remaining(at: date))
        notificationScheduler.schedule(deadline: deadline)
    }
}
