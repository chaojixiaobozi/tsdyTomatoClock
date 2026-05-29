import SwiftUI

/// 设置 / 历史 sheet 顶栏按钮（显式配色，避免系统 bordered 与番茄色脱节）。
struct SettingsChromePrimaryButtonStyle: ButtonStyle {
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(enabled ? TomatoPalette.workAccent : Color.white.opacity(0.22))
            )
            .opacity(configuration.isPressed && enabled ? 0.85 : 1)
    }
}

struct SettingsChromeSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .foregroundColor(.white.opacity(0.92))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.38), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

/// 历史月历内容区的月份切换：与日期格同系的浅底 + 细描边，不用系统灰底 bordered。
struct HistoryMonthNavButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.primary)
            .frame(width: 34, height: 34)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(TomatoPalette.settingsCardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(TomatoPalette.settingsCardStroke, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}
