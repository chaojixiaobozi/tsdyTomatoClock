import Foundation

public enum PomodoroPhase: String, CaseIterable, Codable, Sendable {
    case work
    case shortBreak
    case longBreak

    public var displayTitle: String {
        switch self {
        case .work: return "专注"
        case .shortBreak: return "短休"
        case .longBreak: return "长休"
        }
    }
}

public enum SessionRunState: String, Codable, Sendable {
    case idle
    case running
    case paused
    /// 当前段自然结束，已算出下一段 `phase`，等待用户确认后再开始倒计时。
    case awaitingAdvance
}
