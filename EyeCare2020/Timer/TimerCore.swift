import Foundation

struct TimerCore: Equatable {
    enum Phase: Equatable {
        case work
        case lookAway
    }

    enum Status: Equatable {
        case idle
        case running
        case locked
    }

    enum Event: Equatable {
        case phaseChanged(Phase)
    }

    enum UnlockResult: Equatable {
        case ignored
        case resumed
        case reset
    }

    static let workDuration: TimeInterval = 20 * 60
    static let lookAwayDuration: TimeInterval = 20
    static let maximumResumeLockDuration: TimeInterval = 60

    private(set) var phase: Phase = .work
    private(set) var status: Status = .idle
    private(set) var completedWorkCycles = 0

    private var remainingSnapshot = TimerCore.workDuration
    private var deadline: Date?
    private var lockedAt: Date?

    mutating func start(at date: Date) {
        guard status == .idle else { return }

        phase = .work
        remainingSnapshot = Self.workDuration
        deadline = date.addingTimeInterval(Self.workDuration)
        lockedAt = nil
        status = .running
    }

    mutating func stop(at date: Date) {
        _ = date
        phase = .work
        status = .idle
        remainingSnapshot = Self.workDuration
        deadline = nil
        lockedAt = nil
        completedWorkCycles = 0
    }

    @discardableResult
    mutating func lock(at date: Date) -> Bool {
        guard status == .running else { return false }

        remainingSnapshot = remaining(at: date)
        deadline = nil
        lockedAt = date
        status = .locked
        return true
    }

    mutating func unlock(at date: Date) -> UnlockResult {
        guard status == .locked, let lockedAt else { return .ignored }

        let lockDuration = max(0, date.timeIntervalSince(lockedAt))
        self.lockedAt = nil
        status = .running

        if lockDuration > Self.maximumResumeLockDuration {
            phase = .work
            remainingSnapshot = Self.workDuration
            completedWorkCycles = 0
            deadline = date.addingTimeInterval(Self.workDuration)
            return .reset
        }

        deadline = date.addingTimeInterval(remainingSnapshot)
        return .resumed
    }

    mutating func tick(at date: Date) -> Event? {
        guard status == .running, let deadline, date >= deadline else {
            return nil
        }

        switch phase {
        case .work:
            phase = .lookAway
            remainingSnapshot = Self.lookAwayDuration
            completedWorkCycles += 1
            self.deadline = date.addingTimeInterval(Self.lookAwayDuration)
            return .phaseChanged(.lookAway)

        case .lookAway:
            phase = .work
            remainingSnapshot = Self.workDuration
            self.deadline = date.addingTimeInterval(Self.workDuration)
            return .phaseChanged(.work)
        }
    }

    func remaining(at date: Date) -> TimeInterval {
        guard status == .running, let deadline else {
            return remainingSnapshot
        }

        return max(0, deadline.timeIntervalSince(date))
    }

    func progress(at date: Date) -> Double {
        let duration = phase == .work ? Self.workDuration : Self.lookAwayDuration
        guard duration > 0 else { return 0 }
        return min(max(1 - remaining(at: date) / duration, 0), 1)
    }
}
