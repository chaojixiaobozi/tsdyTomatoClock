import Foundation

/// 纯领域逻辑：计时状态机。不依赖 SwiftUI；时间一律由调用方传入 `now` 便于单测。
public struct PomodoroEngine: Equatable, Sendable {
    public private(set) var config: PomodoroConfig
    public private(set) var phase: PomodoroPhase
    public private(set) var runState: SessionRunState
    public private(set) var segmentDeadline: Date?
    public private(set) var pausedRemaining: TimeInterval?
    /// 当前周期内已完成的工作段数（长休结束后清零）。
    public private(set) var completedWorkInCycle: Int
    public private(set) var todayCompletedPomodoros: Int
    public private(set) var currentCalendarDay: String

    public init(config: PomodoroConfig = .default, calendarDay: String) {
        self.config = config
        self.phase = .work
        self.runState = .idle
        self.segmentDeadline = nil
        self.pausedRemaining = nil
        self.completedWorkInCycle = 0
        self.todayCompletedPomodoros = 0
        self.currentCalendarDay = calendarDay
    }

    public mutating func updateConfig(_ newConfig: PomodoroConfig) {
        config = newConfig
        if runState == .idle {
            segmentDeadline = nil
            pausedRemaining = nil
        }
    }

    public mutating func setTodayCompleted(_ value: Int, calendarDay: String) {
        currentCalendarDay = calendarDay
        todayCompletedPomodoros = max(0, value)
    }

    public mutating func rolloverCalendarDayIfNeeded(calendarDay: String) {
        guard calendarDay != currentCalendarDay else { return }
        currentCalendarDay = calendarDay
        todayCompletedPomodoros = 0
    }

    public func remainingSeconds(at now: Date) -> Int {
        switch runState {
        case .idle:
            return Int(config.workDuration.rounded(.down))
        case .paused:
            return Int((pausedRemaining ?? 0).rounded(.up))
        case .running:
            guard let deadline = segmentDeadline else { return 0 }
            return max(0, Int(deadline.timeIntervalSince(now).rounded(.up)))
        }
    }

    public mutating func start(at now: Date) {
        guard runState == .idle else { return }
        phase = .work
        runState = .running
        segmentDeadline = now.addingTimeInterval(config.workDuration)
        pausedRemaining = nil
    }

    public mutating func pause(at now: Date) {
        guard runState == .running else { return }
        runState = .paused
        let remaining = segmentDeadline.map { max(0, $0.timeIntervalSince(now)) } ?? 0
        pausedRemaining = remaining
        segmentDeadline = nil
    }

    public mutating func resume(at now: Date) {
        guard runState == .paused else { return }
        let remaining = pausedRemaining ?? 0
        runState = .running
        segmentDeadline = now.addingTimeInterval(remaining)
        pausedRemaining = nil
    }

    /// 当前阶段自然结束（计时到点）时传 `naturalCompletion: true`；从工作段跳过则为 `false`，不计入当日番茄数。
    public mutating func acknowledgeSegmentComplete(at now: Date, naturalCompletion: Bool) {
        guard runState == .running else { return }
        switch phase {
        case .work:
            if naturalCompletion {
                todayCompletedPomodoros += 1
                completedWorkInCycle += 1
            }
            let longBreakNext =
                naturalCompletion
                && completedWorkInCycle > 0
                && completedWorkInCycle % config.pomodorosUntilLongBreak == 0
            if longBreakNext {
                phase = .longBreak
                segmentDeadline = now.addingTimeInterval(config.longBreakDuration)
            } else {
                phase = .shortBreak
                segmentDeadline = now.addingTimeInterval(config.shortBreakDuration)
            }
        case .shortBreak:
            phase = .work
            segmentDeadline = now.addingTimeInterval(config.workDuration)
        case .longBreak:
            completedWorkInCycle = 0
            phase = .work
            segmentDeadline = now.addingTimeInterval(config.workDuration)
        }
    }

    public mutating func skipCurrentSegment(at now: Date) {
        acknowledgeSegmentComplete(at: now, naturalCompletion: false)
    }

    /// 重置本轮：回到空闲、阶段回到工作起点；不清除当日完成数。
    public mutating func resetRound() {
        runState = .idle
        phase = .work
        segmentDeadline = nil
        pausedRemaining = nil
        completedWorkInCycle = 0
    }
}
