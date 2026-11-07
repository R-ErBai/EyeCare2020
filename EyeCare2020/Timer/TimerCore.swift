import Foundation

struct TimerCore: Equatable {
    enum Phase: Equatable {
        case work
        case lookAway
    }

    enum Status: Equatable {
        case idle
        case running
        case awaitingRestChoice
        case locked
    }

    enum Event: Equatable {
        case restChoiceRequired
        case phaseChanged(Phase)
    }

    enum UnlockResult: Equatable {
        case ignored
        case resumed
        case resumedRestChoice
        case reset
    }

    enum RestDuration: TimeInterval {
        case twentySeconds = 20
        case oneMinute = 60
    }

    static let defaultWorkMinutes = 20
    static let minimumWorkMinutes = 1
    static let maximumWorkMinutes = 120
    static let lookAwayDuration: TimeInterval = 20
    static let restChoiceDuration: TimeInterval = 5
    static let maximumResumeLockDuration: TimeInterval = 60

    private(set) var phase: Phase = .work
    private(set) var status: Status = .idle
    private(set) var completedWorkCycles = 0
    private(set) var workMinutes: Int

    private var activeWorkDuration: TimeInterval
    private var remainingSnapshot: TimeInterval
    private var deadline: Date?
    private var choiceDeadline: Date?
    private var lockedAt: Date?
    private var lockedWhileAwaitingRestChoice = false

    init(workMinutes: Int = TimerCore.defaultWorkMinutes) {
        let clampedMinutes = min(
            max(workMinutes, TimerCore.minimumWorkMinutes),
            TimerCore.maximumWorkMinutes
        )
        let duration = TimeInterval(clampedMinutes * 60)
        self.workMinutes = clampedMinutes
        activeWorkDuration = duration
        remainingSnapshot = duration
    }

    mutating func start(at date: Date) {
        guard status == .idle else { return }

        phase = .work
        activeWorkDuration = TimeInterval(workMinutes * 60)
        remainingSnapshot = activeWorkDuration
        deadline = date.addingTimeInterval(activeWorkDuration)
        choiceDeadline = nil
        lockedAt = nil
        lockedWhileAwaitingRestChoice = false
        status = .running
    }

    @discardableResult
    mutating func setWorkDuration(minutes: Int) -> Bool {
        guard
            (Self.minimumWorkMinutes...Self.maximumWorkMinutes).contains(minutes)
        else {
            return false
        }

        workMinutes = minutes
        if status == .idle {
            activeWorkDuration = TimeInterval(minutes * 60)
            remainingSnapshot = activeWorkDuration
        }
        return true
    }

    mutating func stop(at date: Date) {
        _ = date
        phase = .work
        status = .idle
        activeWorkDuration = TimeInterval(workMinutes * 60)
        remainingSnapshot = activeWorkDuration
        deadline = nil
        choiceDeadline = nil
        lockedAt = nil
        lockedWhileAwaitingRestChoice = false
        completedWorkCycles = 0
    }

    @discardableResult
    mutating func lock(at date: Date) -> Bool {
        guard status == .running || status == .awaitingRestChoice else {
            return false
        }

        lockedWhileAwaitingRestChoice = status == .awaitingRestChoice
        remainingSnapshot = remaining(at: date)
        deadline = nil
        choiceDeadline = nil
        lockedAt = date
        status = .locked
        return true
    }

    mutating func unlock(at date: Date) -> UnlockResult {
        guard status == .locked, let lockedAt else { return .ignored }

        let lockDuration = max(0, date.timeIntervalSince(lockedAt))
        self.lockedAt = nil

        if lockDuration > Self.maximumResumeLockDuration {
            phase = .work
            status = .running
            activeWorkDuration = TimeInterval(workMinutes * 60)
            remainingSnapshot = activeWorkDuration
            completedWorkCycles = 0
            deadline = date.addingTimeInterval(activeWorkDuration)
            choiceDeadline = nil
            lockedWhileAwaitingRestChoice = false
            return .reset
        }

        if lockedWhileAwaitingRestChoice {
            status = .awaitingRestChoice
            choiceDeadline = date.addingTimeInterval(remainingSnapshot)
            lockedWhileAwaitingRestChoice = false
            return .resumedRestChoice
        }

        status = .running
        deadline = date.addingTimeInterval(remainingSnapshot)
        return .resumed
    }

    @discardableResult
    mutating func selectRest(_ duration: RestDuration, at date: Date) -> Bool {
        let isPendingChoice = status == .awaitingRestChoice
        let isChangingCurrentRest = status == .running && phase == .lookAway
        guard isPendingChoice || isChangingCurrentRest else { return false }

        if isPendingChoice {
            completedWorkCycles += 1
        }

        phase = .lookAway
        status = .running
        remainingSnapshot = duration.rawValue
        deadline = date.addingTimeInterval(duration.rawValue)
        choiceDeadline = nil
        return true
    }

    mutating func tick(at date: Date) -> Event? {
        if status == .awaitingRestChoice,
           let choiceDeadline,
           date >= choiceDeadline {
            _ = selectRest(.twentySeconds, at: date)
            return .phaseChanged(.lookAway)
        }

        guard status == .running, let deadline, date >= deadline else {
            return nil
        }

        switch phase {
        case .work:
            status = .awaitingRestChoice
            remainingSnapshot = Self.restChoiceDuration
            choiceDeadline = date.addingTimeInterval(Self.restChoiceDuration)
            self.deadline = nil
            return .restChoiceRequired

        case .lookAway:
            phase = .work
            activeWorkDuration = TimeInterval(workMinutes * 60)
            remainingSnapshot = activeWorkDuration
            self.deadline = date.addingTimeInterval(activeWorkDuration)
            return .phaseChanged(.work)
        }
    }

    func remaining(at date: Date) -> TimeInterval {
        if status == .running, let deadline {
            return max(0, deadline.timeIntervalSince(date))
        }

        if status == .awaitingRestChoice, let choiceDeadline {
            return max(0, choiceDeadline.timeIntervalSince(date))
        }

        return remainingSnapshot
    }

    func progress(at date: Date) -> Double {
        if status == .awaitingRestChoice {
            return 1
        }

        let duration = phase == .work ? activeWorkDuration : Self.lookAwayDuration
        guard duration > 0 else { return 0 }
        return min(max(1 - remaining(at: date) / duration, 0), 1)
    }
}
