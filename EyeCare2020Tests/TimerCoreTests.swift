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

    func testChangingWorkDurationWhileIdleUpdatesCurrentStartValue() {
        var core = TimerCore()

        let didChange = core.setWorkDuration(minutes: 5)
        core.start(at: epoch)

        XCTAssertTrue(didChange)
        XCTAssertEqual(core.workMinutes, 5)
        XCTAssertEqual(core.remaining(at: epoch), 300, accuracy: 0.001)
    }

    func testChangingWorkDurationDuringWorkAppliesAfterCurrentRest() {
        var core = TimerCore()
        core.start(at: epoch)

        let didChange = core.setWorkDuration(minutes: 5)
        XCTAssertTrue(didChange)
        XCTAssertEqual(core.remaining(at: epoch.addingTimeInterval(100)), 1_100, accuracy: 0.001)

        _ = core.tick(at: epoch.addingTimeInterval(1_200))
        _ = core.selectRest(.twentySeconds, at: epoch.addingTimeInterval(1_205))
        _ = core.tick(at: epoch.addingTimeInterval(1_225))

        XCTAssertEqual(core.phase, .work)
        XCTAssertEqual(core.remaining(at: epoch.addingTimeInterval(1_225)), 300, accuracy: 0.001)
    }

    func testWorkDurationRejectsValuesOutsideSupportedRange() {
        var core = TimerCore()

        XCTAssertFalse(core.setWorkDuration(minutes: 0))
        XCTAssertFalse(core.setWorkDuration(minutes: 121))
        XCTAssertEqual(core.workMinutes, 20)
    }

    func testWorkDeadlineWaitsFiveSecondsForRestChoice() {
        var core = TimerCore()
        core.start(at: epoch)

        let event = core.tick(at: epoch.addingTimeInterval(1_200))

        XCTAssertEqual(event, .restChoiceRequired)
        XCTAssertEqual(core.phase, .work)
        XCTAssertEqual(core.status, .awaitingRestChoice)
        XCTAssertEqual(core.remaining(at: epoch.addingTimeInterval(1_200)), 5, accuracy: 0.001)
        XCTAssertEqual(core.completedWorkCycles, 0)
    }

    func testUnchosenRestDefaultsToTwentySecondsAfterFiveSeconds() {
        var core = TimerCore()
        core.start(at: epoch)
        _ = core.tick(at: epoch.addingTimeInterval(1_200))

        let event = core.tick(at: epoch.addingTimeInterval(1_205))

        XCTAssertEqual(event, .phaseChanged(.lookAway))
        XCTAssertEqual(core.phase, .lookAway)
        XCTAssertEqual(core.status, .running)
        XCTAssertEqual(core.remaining(at: epoch.addingTimeInterval(1_205)), 20, accuracy: 0.001)
        XCTAssertEqual(core.completedWorkCycles, 1)
    }

    func testSelectingOneMinuteStartsSixtySecondRest() {
        var core = TimerCore()
        core.start(at: epoch)
        _ = core.tick(at: epoch.addingTimeInterval(1_200))

        let didSelect = core.selectRest(.oneMinute, at: epoch.addingTimeInterval(1_203))

        XCTAssertTrue(didSelect)
        XCTAssertEqual(core.phase, .lookAway)
        XCTAssertEqual(core.status, .running)
        XCTAssertEqual(core.remaining(at: epoch.addingTimeInterval(1_203)), 60, accuracy: 0.001)
        XCTAssertEqual(core.completedWorkCycles, 1)
        XCTAssertEqual(
            core.tick(at: epoch.addingTimeInterval(1_263)),
            .phaseChanged(.work)
        )
    }

    func testSelectingTwentySecondsStartsTwentySecondRest() {
        var core = TimerCore()
        core.start(at: epoch)
        _ = core.tick(at: epoch.addingTimeInterval(1_200))

        let didSelect = core.selectRest(.twentySeconds, at: epoch.addingTimeInterval(1_203))

        XCTAssertTrue(didSelect)
        XCTAssertEqual(core.phase, .lookAway)
        XCTAssertEqual(core.status, .running)
        XCTAssertEqual(core.remaining(at: epoch.addingTimeInterval(1_203)), 20, accuracy: 0.001)
        XCTAssertEqual(core.completedWorkCycles, 1)
    }

    func testSelectingOneMinuteAfterDefaultRestStartedExtendsCurrentRest() {
        var core = TimerCore()
        core.start(at: epoch)
        _ = core.tick(at: epoch.addingTimeInterval(1_200))
        _ = core.tick(at: epoch.addingTimeInterval(1_205))

        let didSelect = core.selectRest(.oneMinute, at: epoch.addingTimeInterval(1_208))

        XCTAssertTrue(didSelect)
        XCTAssertEqual(core.phase, .lookAway)
        XCTAssertEqual(core.status, .running)
        XCTAssertEqual(core.remaining(at: epoch.addingTimeInterval(1_208)), 60, accuracy: 0.001)
        XCTAssertEqual(core.completedWorkCycles, 1)
    }

    func testLookAwayDeadlineStartsNextWorkPhase() {
        var core = TimerCore()
        core.start(at: epoch)
        _ = core.tick(at: epoch.addingTimeInterval(1_200))
        _ = core.tick(at: epoch.addingTimeInterval(1_205))

        let event = core.tick(at: epoch.addingTimeInterval(1_225))

        XCTAssertEqual(event, .phaseChanged(.work))
        XCTAssertEqual(core.phase, .work)
        XCTAssertEqual(core.status, .running)
        XCTAssertEqual(core.remaining(at: epoch.addingTimeInterval(1_225)), 1_200, accuracy: 0.001)
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
        _ = core.tick(at: epoch.addingTimeInterval(1_205))
        _ = core.lock(at: epoch.addingTimeInterval(1_208))

        let result = core.unlock(at: epoch.addingTimeInterval(1_269))

        XCTAssertEqual(result, .reset)
        XCTAssertEqual(core.phase, .work)
        XCTAssertEqual(core.status, .running)
        XCTAssertEqual(core.remaining(at: epoch.addingTimeInterval(1_269)), 1_200, accuracy: 0.001)
    }

    func testStopReturnsToIdleAndCancelsDeadline() {
        var core = TimerCore()
        core.start(at: epoch)
        _ = core.tick(at: epoch.addingTimeInterval(1_200))
        _ = core.tick(at: epoch.addingTimeInterval(1_205))

        core.stop(at: epoch.addingTimeInterval(1_208))

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

    func testShortLockWhileRestChoicePendingPreservesChoiceCountdown() {
        var core = TimerCore()
        core.start(at: epoch)
        _ = core.tick(at: epoch.addingTimeInterval(1_200))
        _ = core.lock(at: epoch.addingTimeInterval(1_202))

        let result = core.unlock(at: epoch.addingTimeInterval(1_222))

        XCTAssertEqual(result, .resumedRestChoice)
        XCTAssertEqual(core.status, .awaitingRestChoice)
        XCTAssertEqual(core.remaining(at: epoch.addingTimeInterval(1_222)), 3, accuracy: 0.001)
        XCTAssertEqual(
            core.tick(at: epoch.addingTimeInterval(1_225)),
            .phaseChanged(.lookAway)
        )
    }

    func testLongLockWhileRestChoicePendingResetsToFreshWorkCycle() {
        var core = TimerCore()
        core.start(at: epoch)
        _ = core.tick(at: epoch.addingTimeInterval(1_200))
        _ = core.lock(at: epoch.addingTimeInterval(1_202))

        let result = core.unlock(at: epoch.addingTimeInterval(1_263))

        XCTAssertEqual(result, .reset)
        XCTAssertEqual(core.status, .running)
        XCTAssertEqual(core.phase, .work)
        XCTAssertEqual(core.remaining(at: epoch.addingTimeInterval(1_263)), 1_200, accuracy: 0.001)
    }
}
