import SwiftUI

/// 番茄色系（低饱和），配合系统语义色保证可读。
enum TomatoPalette {
    static let workBackground = Color(red: 0.62, green: 0.22, blue: 0.22)
    static let workAccent = Color(red: 0.78, green: 0.32, blue: 0.30)
    static let shortBackground = Color(red: 0.78, green: 0.42, blue: 0.26)
    static let longBackground = Color(red: 0.32, green: 0.52, blue: 0.40)
    static let pausedOverlay = Color.black.opacity(0.12)

    static func background(for phase: PomodoroPhase, runState: SessionRunState) -> LinearGradient {
        let base: Color = {
            switch phase {
            case .work: return workBackground
            case .shortBreak: return shortBackground
            case .longBreak: return longBackground
            }
        }()
        let end = base.opacity(runState == .paused ? 0.55 : 0.85)
        return LinearGradient(colors: [base.opacity(0.95), end], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
