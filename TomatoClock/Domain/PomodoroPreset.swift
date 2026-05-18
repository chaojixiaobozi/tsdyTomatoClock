import Foundation

/// 与 PRD / TECH 一致的三种时长预设（秒）。
public enum PomodoroPreset: String, CaseIterable, Codable, Sendable, Hashable {
    case classic255
    case fortyfive15
    case fiftytwo17

    public var displayName: String {
        switch self {
        case .classic255: return "经典 25/5"
        case .fortyfive15: return "45/15"
        case .fiftytwo17: return "52/17"
        }
    }

    public var config: PomodoroConfig {
        switch self {
        case .classic255:
            return PomodoroConfig(
                workDuration: 25 * 60,
                shortBreakDuration: 5 * 60,
                longBreakDuration: 15 * 60,
                pomodorosUntilLongBreak: 4
            )
        case .fortyfive15:
            return PomodoroConfig(
                workDuration: 45 * 60,
                shortBreakDuration: 15 * 60,
                longBreakDuration: 15 * 60,
                pomodorosUntilLongBreak: 4
            )
        case .fiftytwo17:
            return PomodoroConfig(
                workDuration: 52 * 60,
                shortBreakDuration: 17 * 60,
                longBreakDuration: 30 * 60,
                pomodorosUntilLongBreak: 4
            )
        }
    }
}
