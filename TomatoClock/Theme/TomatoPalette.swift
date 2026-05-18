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

    /// 设置页：与主界面同系的番茄红 → 浅绿过渡，略柔于专注态全屏。
    static var settingsBackground: LinearGradient {
        LinearGradient(
            colors: [
                workBackground.opacity(0.92),
                shortBackground.opacity(0.45),
                longBackground.opacity(0.38)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// 设置页顶/底栏：略深于内容区，与主界面 work 色带呼应。
    static var settingsChromeBar: LinearGradient {
        LinearGradient(
            colors: [
                workBackground.opacity(0.94),
                workBackground.opacity(0.78)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// 设置卡片：浅底 + 细边框，保证在渐变背景上可读。
    static let settingsCardFill = Color.primary.opacity(0.06)
    static let settingsCardStroke = Color.primary.opacity(0.12)

    // MARK: - 主界面按钮（避免系统 Prominent 白字与暖色底冲突）

    /// 主按钮填充：随阶段略变的暖浅底。
    static func timerPrimaryFill(for phase: PomodoroPhase) -> Color {
        switch phase {
        case .work: return Color(red: 0.90, green: 0.74, blue: 0.71)
        case .shortBreak: return Color(red: 0.94, green: 0.84, blue: 0.74)
        case .longBreak: return Color(red: 0.80, green: 0.90, blue: 0.84)
        }
    }

    /// 主按钮文字：深暖色，保证在浅色填充上可读。
    static func timerPrimaryLabel(for phase: PomodoroPhase) -> Color {
        switch phase {
        case .work: return Color(red: 0.32, green: 0.13, blue: 0.12)
        case .shortBreak: return Color(red: 0.34, green: 0.22, blue: 0.10)
        case .longBreak: return Color(red: 0.14, green: 0.28, blue: 0.22)
        }
    }

    /// 次按钮：半透明底，随系统浅/深自动反色。
    static let timerSecondaryFill = Color.primary.opacity(0.10)

    /// 次按钮描边：带一点阶段色相，避免「一片白框」。
    static func timerSecondaryStroke(for phase: PomodoroPhase) -> Color {
        switch phase {
        case .work: return workAccent.opacity(0.55)
        case .shortBreak: return shortBackground.opacity(0.65)
        case .longBreak: return longBackground.opacity(0.70)
        }
    }
}
