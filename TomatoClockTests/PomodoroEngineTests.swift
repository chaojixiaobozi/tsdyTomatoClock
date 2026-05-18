import XCTest
@testable import TomatoClock

final class PomodoroEngineTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_000_000)

    func testStartFromIdleSetsWorkDeadline() {
        var e = PomodoroEngine(config: .default, calendarDay: "2026-05-18")
        e.start(at: t0)
        XCTAssertEqual(e.runState, .running)
        XCTAssertEqual(e.phase, .work)
        XCTAssertEqual(e.remainingSeconds(at: t0), 25 * 60)
        let t1 = t0.addingTimeInterval(60)
        XCTAssertEqual(e.remainingSeconds(at: t1), 25 * 60 - 60)
    }

    func testPauseResumePreservesRemaining() {
        var e = PomodoroEngine(config: .default, calendarDay: "2026-05-18")
        e.start(at: t0)
        let tMid = t0.addingTimeInterval(60)
        XCTAssertEqual(e.remainingSeconds(at: tMid), 25 * 60 - 60)
        e.pause(at: tMid)
        XCTAssertEqual(e.runState, .paused)
        XCTAssertEqual(e.remainingSeconds(at: tMid.addingTimeInterval(999)), 25 * 60 - 60)
        let tResume = tMid.addingTimeInterval(10)
        e.resume(at: tResume)
        XCTAssertEqual(e.runState, .running)
        XCTAssertEqual(e.remainingSeconds(at: tResume), 25 * 60 - 60)
    }

    func testNaturalWorkCompletionGoesAwaitingShortBreakThenConfirmRuns() {
        var e = PomodoroEngine(config: .default, calendarDay: "2026-05-18")
        e.start(at: t0)
        let end = t0.addingTimeInterval(25 * 60)
        e.completeCurrentSegmentNaturally(at: end)
        XCTAssertEqual(e.todayCompletedPomodoros, 1)
        XCTAssertEqual(e.completedWorkInCycle, 1)
        XCTAssertEqual(e.phase, .shortBreak)
        XCTAssertEqual(e.runState, .awaitingAdvance)
        XCTAssertEqual(e.remainingSeconds(at: end), 0)

        e.confirmAdvance(at: end)
        XCTAssertEqual(e.runState, .running)
        XCTAssertEqual(e.remainingSeconds(at: end), 5 * 60)
    }

    func testFourthNaturalWorkGoesLongBreakAfterConfirmChain() {
        var cfg = PomodoroConfig.default
        cfg.workDuration = 60
        cfg.shortBreakDuration = 30
        cfg.longBreakDuration = 90
        cfg.pomodorosUntilLongBreak = 4
        var e = PomodoroEngine(config: cfg, calendarDay: "2026-05-18")

        var now = t0
        e.start(at: now)

        for round in 1...3 {
            XCTAssertEqual(e.phase, .work, "round \(round)")
            now = now.addingTimeInterval(60)
            e.completeCurrentSegmentNaturally(at: now)
            XCTAssertEqual(e.runState, .awaitingAdvance)
            XCTAssertEqual(e.phase, .shortBreak)
            e.confirmAdvance(at: now)
            XCTAssertEqual(e.runState, .running)

            now = now.addingTimeInterval(30)
            e.completeCurrentSegmentNaturally(at: now)
            XCTAssertEqual(e.runState, .awaitingAdvance)
            XCTAssertEqual(e.phase, .work)
            e.confirmAdvance(at: now)
            XCTAssertEqual(e.runState, .running)
        }

        XCTAssertEqual(e.phase, .work)
        now = now.addingTimeInterval(60)
        e.completeCurrentSegmentNaturally(at: now)
        XCTAssertEqual(e.phase, .longBreak)
        XCTAssertEqual(e.runState, .awaitingAdvance)
        XCTAssertEqual(e.completedWorkInCycle, 4)
        XCTAssertEqual(e.todayCompletedPomodoros, 4)

        e.confirmAdvance(at: now)
        XCTAssertEqual(e.runState, .running)
        XCTAssertEqual(e.remainingSeconds(at: now), 90)
    }

    func testLongBreakCompletionResetsCycleAfterConfirm() {
        var cfg = PomodoroConfig.default
        cfg.workDuration = 10
        cfg.shortBreakDuration = 5
        cfg.longBreakDuration = 12
        cfg.pomodorosUntilLongBreak = 4
        var e = PomodoroEngine(config: cfg, calendarDay: "2026-05-18")
        var now = t0
        e.start(at: now)

        for _ in 1...3 {
            XCTAssertEqual(e.phase, .work)
            now = now.addingTimeInterval(10)
            e.completeCurrentSegmentNaturally(at: now)
            e.confirmAdvance(at: now)
            XCTAssertEqual(e.phase, .shortBreak)
            now = now.addingTimeInterval(5)
            e.completeCurrentSegmentNaturally(at: now)
            e.confirmAdvance(at: now)
        }

        XCTAssertEqual(e.phase, .work)
        now = now.addingTimeInterval(10)
        e.completeCurrentSegmentNaturally(at: now)
        XCTAssertEqual(e.phase, .longBreak)
        e.confirmAdvance(at: now)

        now = now.addingTimeInterval(12)
        e.completeCurrentSegmentNaturally(at: now)
        XCTAssertEqual(e.phase, .work)
        XCTAssertEqual(e.runState, .awaitingAdvance)
        XCTAssertEqual(e.completedWorkInCycle, 0)

        e.confirmAdvance(at: now)
        XCTAssertEqual(e.runState, .running)
        XCTAssertEqual(e.completedWorkInCycle, 0)
    }

    func testSkipWorkDoesNotIncrementTodayAndAlwaysShortBreak() {
        var e = PomodoroEngine(config: .default, calendarDay: "2026-05-18")
        e.start(at: t0)
        e.skipCurrentSegment(at: t0.addingTimeInterval(1))
        XCTAssertEqual(e.todayCompletedPomodoros, 0)
        XCTAssertEqual(e.completedWorkInCycle, 0)
        XCTAssertEqual(e.phase, .shortBreak)
        XCTAssertEqual(e.runState, .running)
    }

    func testResetRoundClearsCycleButKeepsToday() {
        var e = PomodoroEngine(config: .default, calendarDay: "2026-05-18")
        e.start(at: t0)
        let end = t0.addingTimeInterval(25 * 60)
        e.completeCurrentSegmentNaturally(at: end)
        XCTAssertEqual(e.todayCompletedPomodoros, 1)
        e.resetRound()
        XCTAssertEqual(e.runState, .idle)
        XCTAssertEqual(e.completedWorkInCycle, 0)
        XCTAssertEqual(e.todayCompletedPomodoros, 1)
    }

    func testRolloverCalendarDayResetsToday() {
        var e = PomodoroEngine(config: .default, calendarDay: "2026-05-18")
        e.setTodayCompleted(3, calendarDay: "2026-05-18")
        e.rolloverCalendarDayIfNeeded(calendarDay: "2026-05-19")
        XCTAssertEqual(e.todayCompletedPomodoros, 0)
        XCTAssertEqual(e.currentCalendarDay, "2026-05-19")
    }

    func testPresetConfigsMatchTable() {
        let c255 = PomodoroPreset.classic255.config
        XCTAssertEqual(c255.workDuration, 25 * 60)
        XCTAssertEqual(c255.shortBreakDuration, 5 * 60)
        XCTAssertEqual(c255.longBreakDuration, 15 * 60)

        let c4515 = PomodoroPreset.fortyfive15.config
        XCTAssertEqual(c4515.workDuration, 45 * 60)
        XCTAssertEqual(c4515.shortBreakDuration, 15 * 60)
        XCTAssertEqual(c4515.longBreakDuration, 15 * 60)

        let c5217 = PomodoroPreset.fiftytwo17.config
        XCTAssertEqual(c5217.workDuration, 52 * 60)
        XCTAssertEqual(c5217.shortBreakDuration, 17 * 60)
        XCTAssertEqual(c5217.longBreakDuration, 30 * 60)
    }
}
