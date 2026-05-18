import Foundation

public struct PomodoroConfig: Equatable, Codable, Sendable {
    public var workDuration: TimeInterval
    public var shortBreakDuration: TimeInterval
    public var longBreakDuration: TimeInterval
    /// 完成多少个「工作段」后，下一次进入长休（默认 4）。
    public var pomodorosUntilLongBreak: Int

    public init(
        workDuration: TimeInterval,
        shortBreakDuration: TimeInterval,
        longBreakDuration: TimeInterval,
        pomodorosUntilLongBreak: Int
    ) {
        self.workDuration = workDuration
        self.shortBreakDuration = shortBreakDuration
        self.longBreakDuration = longBreakDuration
        self.pomodorosUntilLongBreak = max(1, pomodorosUntilLongBreak)
    }

    public static let `default` = PomodoroConfig(
        workDuration: 25 * 60,
        shortBreakDuration: 5 * 60,
        longBreakDuration: 15 * 60,
        pomodorosUntilLongBreak: 4
    )
}
