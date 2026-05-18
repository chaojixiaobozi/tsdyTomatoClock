import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: TimerViewModel
    @Environment(\.dismiss) private var dismiss

    private var idle: Bool { viewModel.engine.runState == .idle }

    private var allowsPresetChange: Bool { viewModel.allowsPresetChange }

    private var draftMatchingPreset: PomodoroPreset? {
        TimerViewModel.matchingPreset(for: viewModel.configDraft)
    }

    var body: some View {
        ZStack {
            TomatoPalette.settingsBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                settingsChromeHeader

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        sectionCard(title: "时长预设") {
                            Text("一键应用常见节奏；「每几轮后长休」默认仍为 4，可在下方修改。")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: 8),
                                    GridItem(.flexible(), spacing: 8),
                                    GridItem(.flexible(), spacing: 8)
                                ],
                                spacing: 8
                            ) {
                                ForEach(Array(PomodoroPreset.allCases), id: \.self) { preset in
                                    presetChip(preset: preset)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }

                        sectionCard(title: "时长（分钟）") {
                            Stepper(value: workBinding, in: 1...120) {
                                Text("专注：\(Int(viewModel.configDraft.workDuration / 60))")
                            }
                            .accessibilityIdentifier("settings.workMinutes")
                            Stepper(value: shortBinding, in: 1...60) {
                                Text("短休：\(Int(viewModel.configDraft.shortBreakDuration / 60))")
                            }
                            .accessibilityIdentifier("settings.shortMinutes")
                            Stepper(value: longBinding, in: 1...60) {
                                Text("长休：\(Int(viewModel.configDraft.longBreakDuration / 60))")
                            }
                            .accessibilityIdentifier("settings.longMinutes")
                        }

                        sectionCard(title: "轮次") {
                            Stepper(
                                value: Binding(
                                    get: { viewModel.configDraft.pomodorosUntilLongBreak },
                                    set: { viewModel.configDraft.pomodorosUntilLongBreak = max(1, $0) }
                                ),
                                in: 1...12
                            ) {
                                Text("每 \(viewModel.configDraft.pomodorosUntilLongBreak) 个番茄后长休")
                            }
                            .accessibilityIdentifier("settings.pomodorosUntilLong")
                        }

                        Text("在「空闲」或「本段已结束、待进入下一段」时可切换预设；计时或暂停中不可改。保存自定义时长仍须在空闲时。")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                settingsChromeFooter
            }
        }
        /// 与主窗口 `TimerRootView` 的 min 尺寸对齐，避免 sheet 过宽出现「半屏留白」观感。
        .frame(width: 360, height: 488)
        .onAppear {
            viewModel.configDraft = viewModel.engine.config
        }
    }

    private var settingsChromeHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("设置")
                .font(.title2.weight(.semibold))
                .foregroundColor(.white.opacity(0.95))
            Spacer(minLength: 8)
            Button("关闭") {
                dismiss()
            }
            .buttonStyle(SettingsChromeSecondaryButtonStyle())
            .accessibilityIdentifier("settings.closeButton")

            Button("保存") {
                viewModel.applySettingsIfPossible()
                dismiss()
            }
            .buttonStyle(SettingsChromePrimaryButtonStyle(enabled: idle))
            .accessibilityIdentifier("settings.saveButton")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(TomatoPalette.settingsChromeBar)
    }

    private var settingsChromeFooter: some View {
        TomatoPalette.settingsChromeBar
            .frame(height: 12)
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(TomatoPalette.settingsCardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(TomatoPalette.settingsCardStroke, lineWidth: 1)
                )
        )
    }

    private func presetChip(preset: PomodoroPreset) -> some View {
        let selected = draftMatchingPreset == preset
        return Button {
            viewModel.applyPreset(preset)
        } label: {
            Text(preset.displayName)
                .font(.callout.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .foregroundColor(selected ? .white : .primary)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(selected ? TomatoPalette.workAccent : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(
                            selected ? TomatoPalette.workAccent : TomatoPalette.settingsCardStroke,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .disabled(!allowsPresetChange)
        .opacity(allowsPresetChange ? 1 : 0.5)
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityIdentifier("settings.preset.\(preset.rawValue)")
    }

    private var workBinding: Binding<Int> {
        Binding(
            get: { Int(viewModel.configDraft.workDuration / 60) },
            set: { viewModel.configDraft.workDuration = TimeInterval($0 * 60) }
        )
    }

    private var shortBinding: Binding<Int> {
        Binding(
            get: { Int(viewModel.configDraft.shortBreakDuration / 60) },
            set: { viewModel.configDraft.shortBreakDuration = TimeInterval($0 * 60) }
        )
    }

    private var longBinding: Binding<Int> {
        Binding(
            get: { Int(viewModel.configDraft.longBreakDuration / 60) },
            set: { viewModel.configDraft.longBreakDuration = TimeInterval($0 * 60) }
        )
    }
}

// MARK: - 顶栏按钮（显式配色，避免系统 toolbar 与番茄色脱节）

private struct SettingsChromePrimaryButtonStyle: ButtonStyle {
    var enabled: Bool

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

private struct SettingsChromeSecondaryButtonStyle: ButtonStyle {
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
