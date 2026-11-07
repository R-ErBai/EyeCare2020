import Combine
import Foundation
import UIKit
import UserNotifications

@MainActor
final class TimerViewModel: ObservableObject {
    @Published private(set) var phase: TimerCore.Phase = .work
    @Published private(set) var status: TimerCore.Status = .idle
    @Published private(set) var remaining = TimeInterval(TimerCore.defaultWorkMinutes * 60)
    @Published private(set) var progress: Double = 0
    @Published private(set) var completedWorkCycles = 0
    @Published private(set) var notice: String?
    @Published private(set) var restChoiceSecondsRemaining = 0
    @Published private(set) var notificationPermissionDenied = false
    @Published private(set) var workMinutes: Int
    @Published private(set) var restEndSound: RestEndSound

    private var core: TimerCore
    private var ticker: AnyCancellable?
    private var permissionRequested = false
    private let userDefaults: UserDefaults
    private let restSoundPlayer: RestSoundPlayer
    private let liveActivityManager: LiveActivityManager
    private static let notificationDeniedMessage =
        "通知权限未开启。前台仍会弹选择框，后台到点可能没有提醒。"
    private static let workMinutesDefaultsKey = "workDurationMinutes"
    private static let restEndSoundDefaultsKey = "restEndSound"

    private let dateProvider: () -> Date
    private let notificationScheduler: NotificationScheduler
    private let backgroundAudioKeeper: BackgroundAudioKeeper
    private let lockObserver: LockObserver
    private let haptic = UINotificationFeedbackGenerator()

    init(
        dateProvider: @escaping () -> Date = Date.init,
        notificationScheduler: NotificationScheduler = NotificationScheduler(),
        backgroundAudioKeeper: BackgroundAudioKeeper = BackgroundAudioKeeper(),
        lockObserver: LockObserver = LockObserver(),
        userDefaults: UserDefaults = .standard,
        restSoundPlayer: RestSoundPlayer = RestSoundPlayer(),
        liveActivityManager: LiveActivityManager? = nil
    ) {
        let storedMinutes = userDefaults.object(
            forKey: Self.workMinutesDefaultsKey
        ) as? Int
        let initialMinutes = min(
            max(
                storedMinutes ?? TimerCore.defaultWorkMinutes,
                TimerCore.minimumWorkMinutes
            ),
            TimerCore.maximumWorkMinutes
        )
        let storedSound = userDefaults.string(
            forKey: Self.restEndSoundDefaultsKey
        )
        let initialSound = RestEndSound(rawValue: storedSound ?? "")
            ?? .defaultSound

        self.dateProvider = dateProvider
        self.notificationScheduler = notificationScheduler
        self.backgroundAudioKeeper = backgroundAudioKeeper
        self.lockObserver = lockObserver
        self.userDefaults = userDefaults
        self.restSoundPlayer = restSoundPlayer
        self.liveActivityManager = liveActivityManager ?? LiveActivityManager()
        self.workMinutes = initialMinutes
        self.restEndSound = initialSound
        self.core = TimerCore(workMinutes: initialMinutes)

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
        refreshNotificationAuthorization()
    }

    var isRunning: Bool {
        status != .idle
    }

    var isAwaitingRestChoice: Bool {
        status == .awaitingRestChoice
    }

    var timeText: String {
        let totalSeconds = max(0, Int(ceil(remaining)))
        return String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    var phaseTitle: String {
        switch status {
        case .idle:
            return "准备开始"
        case .awaitingRestChoice:
            return "该休息了"
        case .locked:
            return "屏幕已锁定"
        case .running:
            return phase == .work ? "用眼计时" : "看向远处"
        }
    }

    var phaseSubtitle: String {
        switch status {
        case .idle:
            return "每 \(workMinutes) 分钟，让眼睛休息 20 秒或 1 分钟"
        case .awaitingRestChoice:
            return "选择休息 20 秒，或延长到 1 分钟"
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
        syncLiveActivity(at: now)
        requestPermissionAndSchedule()
    }

    func stop() {
        let now = dateProvider()
        core.stop(at: now)
        ticker?.cancel()
        ticker = nil
        backgroundAudioKeeper.stop()
        restSoundPlayer.stop()
        liveActivityManager.end()
        notificationScheduler.cancelAll()
        notice = nil
        sync(at: now)
    }

    func setWorkDuration(minutes: Int) {
        let now = dateProvider()
        guard core.setWorkDuration(minutes: minutes) else { return }

        workMinutes = core.workMinutes
        userDefaults.set(workMinutes, forKey: Self.workMinutesDefaultsKey)
        notice = status == .idle
            ? "下一轮将按 \(workMinutes) 分钟计时"
            : "新的用眼时长将在下一轮生效"
        sync(at: now)
        if isRunning {
            syncLiveActivity(at: now)
        }
    }

    func setRestEndSound(_ sound: RestEndSound) {
        restEndSound = sound
        userDefaults.set(sound.rawValue, forKey: Self.restEndSoundDefaultsKey)
        restSoundPlayer.play(sound)
    }

    func previewRestEndSound() {
        restSoundPlayer.play(restEndSound)
    }

    func selectRest(_ duration: TimerCore.RestDuration) {
        let now = dateProvider()
        handleTick(now)
        guard core.selectRest(duration, at: now) else { return }

        notice = duration == .oneMinute ? "这次休息 1 分钟" : "这次休息 20 秒"
        startTicker()
        backgroundAudioKeeper.start()
        haptic.notificationOccurred(.success)
        scheduleCurrentDeadline(at: now)
        sync(at: now)
        syncLiveActivity(at: now)
    }

    func handleNotificationAction(identifier: String) {
        switch identifier {
        case NotificationSchedule.restTwentySecondsActionIdentifier:
            selectRest(.twentySeconds)
        case NotificationSchedule.restOneMinuteActionIdentifier:
            selectRest(.oneMinute)
        default:
            break
        }
    }

    func handleNotificationOpen(requestIdentifier: String) {
        guard requestIdentifier == NotificationSchedule.restChoiceRequestIdentifier else {
            return
        }

        handleTick(dateProvider())
    }

    func refreshNotificationAuthorization() {
        notificationScheduler.authorizationStatus { [weak self] status in
            Task { @MainActor in
                guard let self else { return }

                self.notificationPermissionDenied = status == .denied
                if status == .authorized || status == .provisional {
                    if self.notice == Self.notificationDeniedMessage {
                        self.notice = nil
                    }
                } else if status == .denied, self.isRunning {
                    self.notice = Self.notificationDeniedMessage
                }
            }
        }
    }

    func openNotificationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        UIApplication.shared.open(url)
    }

    func handleTick(_ now: Date) {
        let didTransition: Bool
        if let event = core.tick(at: now) {
            didTransition = true
            switch event {
            case .restChoiceRequired:
                haptic.notificationOccurred(.warning)
                scheduleRestEndFallback(at: now)

            case .phaseChanged(.lookAway):
                haptic.notificationOccurred(.success)
                scheduleCurrentDeadline(at: now)

            case .phaseChanged(.work):
                haptic.notificationOccurred(.success)
                notice = "休息结束，可以继续下一轮用眼了"
                playRestEndSound()
                scheduleCurrentDeadline(at: now)
            }
        } else {
            didTransition = false
        }

        sync(at: now)
        if didTransition {
            syncLiveActivity(at: now)
        }
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
        restChoiceSecondsRemaining = status == .awaitingRestChoice
            ? max(0, Int(ceil(remaining)))
            : 0
    }

    private func handleLock() {
        let now = dateProvider()
        guard core.lock(at: now) else { return }

        ticker?.cancel()
        ticker = nil
        notificationScheduler.cancelAll()
        sync(at: now)
        syncLiveActivity(at: now)
    }

    private func handleUnlock() {
        let now = dateProvider()
        let result = core.unlock(at: now)

        switch result {
        case .ignored:
            return

        case .resumed:
            notice = "已接着刚才的进度计时"

        case .resumedRestChoice:
            notice = "已恢复休息选择"

        case .reset:
            notice = "离开超过 1 分钟，已重新开始 20 分钟"
        }

        startTicker()
        backgroundAudioKeeper.start()
        sync(at: now)
        scheduleCurrentDeadline(at: now)
        syncLiveActivity(at: now)
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
                    self.notificationPermissionDenied = true
                    self.notice = Self.notificationDeniedMessage
                }
            }
        }
    }

    private func scheduleCurrentDeadline(at date: Date) {
        switch core.status {
        case .idle, .locked:
            notificationScheduler.cancelAll()
            return

        case .awaitingRestChoice:
            let remaining = core.remaining(at: date)
            notificationScheduler.schedule(
                .restChoice(deadline: date.addingTimeInterval(remaining))
            )
            notificationScheduler.schedule(
                .restEnd(
                    deadline: date.addingTimeInterval(
                        remaining + TimerCore.lookAwayDuration
                    )
                )
            )

        case .running:
            switch core.phase {
            case .work:
                notificationScheduler.schedule(
                    .restChoice(
                        deadline: date.addingTimeInterval(core.remaining(at: date))
                    )
                )

            case .lookAway:
                notificationScheduler.schedule(
                    .restEnd(
                        deadline: date.addingTimeInterval(core.remaining(at: date))
                    )
                )
            }
        }
    }

    private func scheduleRestEndFallback(at date: Date) {
        notificationScheduler.schedule(
            .restEnd(
                deadline: date.addingTimeInterval(
                    TimerCore.restChoiceDuration + TimerCore.lookAwayDuration
                )
            )
        )
    }

    private func playRestEndSound() {
        restSoundPlayer.play(restEndSound)
    }

    private func syncLiveActivity(at date: Date) {
        switch core.status {
        case .idle:
            liveActivityManager.end()

        case .locked:
            liveActivityManager.update(
                phase: liveActivityPhase,
                status: .paused,
                deadline: nil,
                remaining: core.remaining(at: date),
                workMinutes: workMinutes
            )

        case .awaitingRestChoice:
            let remaining = core.remaining(at: date)
            liveActivityManager.update(
                phase: .restChoice,
                status: .waiting,
                deadline: date.addingTimeInterval(remaining),
                remaining: remaining,
                workMinutes: workMinutes
            )

        case .running:
            let remaining = core.remaining(at: date)
            liveActivityManager.update(
                phase: liveActivityPhase,
                status: .running,
                deadline: date.addingTimeInterval(remaining),
                remaining: remaining,
                workMinutes: workMinutes
            )
        }
    }

    private var liveActivityPhase: EyeCareActivityPhase {
        switch core.phase {
        case .work:
            return .work
        case .lookAway:
            return .lookAway
        }
    }
}
