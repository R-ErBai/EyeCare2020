import XCTest
#if canImport(EyeCare2020Core)
@testable import EyeCare2020Core
#else
@testable import EyeCare2020
#endif

final class TimerCoreTests: XCTestCase {
    private let epoch = Date(timeIntervalSince1970: 1_000_000)

    func testInitialStateIsIdleWorkAtTwentyMinutes() {
        let core = TimerCore()

        XCTAssertEqual(core.phase, .work)
        XCTAssertEqual(core.status, .idle)
        XCTAssertEqual(core.remaining(at: epoch), 1_200, accuracy: 0.001)
        XCTAssertEqual(core.completedWorkCycles, 0)
    }

    func testStartBeginsTwentyMinuteDeadline() {
        var core = TimerCore()

        core.start(at: epoch)

        XCTAssertEqual(core.status, .running)
        XCTAssertEqual(core.phase, .work)
        XCTAssertEqual(core.remaining(at: epoch), 1_200, accuracy: 0.001)
        XCTAssertEqual(core.remaining(at: epoch.addingTimeInterval(300)), 900, accuracy: 0.001)
    }

    func testWorkDeadlineStartsTwentySecondLookAwayPhase() {
        var core = TimerCore()
        core.start(at: epoch)

        let event = core.tick(at: epoch.addingTimeInterval(1_200))

        XCTAssertEqual(event, .phaseChanged(.lookAway))
        XCTAssertEqual(core.phase, .lookAway)
        XCTAssertEqual(core.status, .running)
        XCTAssertEqual(core.remaining(at: epoch.addingTimeInterval(1_200)), 20, accuracy: 0.001)
        XCTAssertEqual(core.completedWorkCycles, 1)
    }

    func testLookAwayDeadlineStartsNextWorkPhase() {
        var core = TimerCore()
        core.start(at: epoch)
        _ = core.tick(at: epoch.addingTimeInterval(1_200))

        let event = core.tick(at: epoch.addingTimeInterval(1_220))

        XCTAssertEqual(event, .phaseChanged(.work))
        XCTAssertEqual(core.phase, .work)
        XCTAssertEqual(core.status, .running)
        XCTAssertEqual(core.remaining(at: epoch.addingTimeInterval(1_220)), 1_200, accuracy: 0.001)
        XCTAssertEqual(core.completedWorkCycles, 1)
    }

    func testLockPausesAndPreservesRemainingTime() {
        var core = TimerCore()
        core.start(at: epoch)

        let didLock = core.lock(at: epoch.addingTimeInterval(340))

        XCTAssertTrue(didLock)
        XCTAssertEqual(core.status, .locked)
        XCTAssertEqual(core.remaining(at: epoch.addingTimeInterval(10_000)), 860, accuracy: 0.001)
        XCTAssertNil(core.tick(at: epoch.addingTimeInterval(10_000)))
    }

    func testExactlySixtySecondsUnlocksAndResumes() {
        var core = TimerCore()
        core.start(at: epoch)
        _ = core.lock(at: epoch.addingTimeInterval(300))

        let result = core.unlock(at: epoch.addingTimeInterval(360))

        XCTAssertEqual(result, .resumed)
        XCTAssertEqual(core.status, .running)
        XCTAssertEqual(core.phase, .work)
        XCTAssertEqual(core.remaining(at: epoch.addingTimeInterval(360)), 900, accuracy: 0.001)
    }

    func testSixtyOneSecondsUnlocksWithFreshTwentyMinuteCycle() {
        var core = TimerCore()
        core.start(at: epoch)
        _ = core.lock(at: epoch.addingTimeInterval(300))

        let result = core.unlock(at: epoch.addingTimeInterval(361))

        XCTAssertEqual(result, .reset)
        XCTAssertEqual(core.status, .running)
        XCTAssertEqual(core.phase, .work)
        XCTAssertEqual(core.remaining(at: epoch.addingTimeInterval(361)), 1_200, accuracy: 0.001)
        XCTAssertEqual(core.completedWorkCycles, 0)
    }

    func testLongLockDuringLookAwayResetsToWorkAndStarts() {
        var core = TimerCore()
        core.start(at: epoch)
        _ = core.tick(at: epoch.addingTimeInterval(1_200))
        _ = core.lock(at: epoch.addingTimeInterval(1_205))

        let result = core.unlock(at: epoch.addingTimeInterval(1_266))

        XCTAssertEqual(result, .reset)
        XCTAssertEqual(core.phase, .work)
        XCTAssertEqual(core.status, .running)
        XCTAssertEqual(core.remaining(at: epoch.addingTimeInterval(1_266)), 1_200, accuracy: 0.001)
    }

    func testStopReturnsToIdleAndCancelsDeadline() {
        var core = TimerCore()
        core.start(at: epoch)
        _ = core.tick(at: epoch.addingTimeInterval(1_200))

        core.stop(at: epoch.addingTimeInterval(1_205))

        XCTAssertEqual(core.phase, .work)
        XCTAssertEqual(core.status, .idle)
        XCTAssertEqual(core.remaining(at: epoch.addingTimeInterval(10_000)), 1_200, accuracy: 0.001)
        XCTAssertEqual(core.completedWorkCycles, 0)
        XCTAssertNil(core.tick(at: epoch.addingTimeInterval(10_000)))
    }

    func testUnlockWithoutLockIsIgnored() {
        var core = TimerCore()
        core.start(at: epoch)

        XCTAssertEqual(core.unlock(at: epoch.addingTimeInterval(10)), .ignored)
        XCTAssertEqual(core.status, .running)
    }

    func testLockWhileIdleIsIgnored() {
        var core = TimerCore()

        XCTAssertFalse(core.lock(at: epoch))
        XCTAssertEqual(core.status, .idle)
    }
}
