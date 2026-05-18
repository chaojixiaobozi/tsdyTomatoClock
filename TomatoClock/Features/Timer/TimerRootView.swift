import SwiftUI

struct TimerRootView: View {
    @StateObject private var viewModel = TimerViewModel()
    @State private var showSettings = false

    var body: some View {
        ZStack {
            TomatoPalette.background(
                for: viewModel.engine.phase,
                runState: displayRunState
            )
            .ignoresSafeArea()

            if viewModel.engine.runState == .paused {
                TomatoPalette.pausedOverlay
                    .ignoresSafeArea()
            }

            VStack(spacing: 20) {
                header
                Spacer(minLength: 8)
                phaseLabel
                remainingLabel
                todayRow
                Spacer(minLength: 8)
                controls
            }
            .padding(28)
        }
        .overlay(
            WindowBridge()
                .frame(width: 1, height: 1)
                .allowsHitTesting(false)
        )
        .frame(minWidth: 360, minHeight: 420)
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.requestNotifications()
        }
    }

    /// 待确认时用「空闲」级渐变强度，避免与暂停蒙层叠加语义冲突。
    private var displayRunState: SessionRunState {
        switch viewModel.engine.runState {
        case .awaitingAdvance: return .idle
        default: return viewModel.engine.runState
        }
    }

    private var header: some View {
        HStack {
            Text("TsdyTomatoClock")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
            Spacer()
            Button("设置") {
                showSettings = true
            }
            .buttonStyle(TomatoTimerSecondaryButtonStyle(phase: viewModel.engine.phase, enabled: true))
            .accessibilityIdentifier("timer.settingsButton")
        }
    }

    private var phaseLabel: some View {
        Text(viewModel.phaseHeadline())
            .font(.title3)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .accessibilityIdentifier("timer.phaseLabel")
    }

    private var remainingLabel: some View {
        Text(viewModel.formattedRemaining())
            .font(.system(size: 64, weight: .medium, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.primary)
            .accessibilityIdentifier("timer.remainingLabel")
    }

    private var todayRow: some View {
        HStack(spacing: 8) {
            Text("今日完成")
                .foregroundStyle(.secondary)
            Text("\(viewModel.engine.todayCompletedPomodoros)")
                .font(.title3.weight(.semibold))
                .accessibilityIdentifier("timer.todayCount")
        }
    }

    private var secondaryActionEnabled: Bool {
        viewModel.engine.runState != .idle
    }

    private var controls: some View {
        let phase = viewModel.engine.phase
        return VStack(spacing: 12) {
            if viewModel.notificationDenied {
                Text("未开启通知权限，阶段结束时可能收不到系统提醒。可在「系统设置 → 通知」中开启。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("timer.notificationHint")
            }

            if viewModel.engine.runState == .awaitingAdvance {
                VStack(spacing: 10) {
                    Button("进入下一阶段") {
                        viewModel.confirmAdvance()
                    }
                    .buttonStyle(TomatoTimerPrimaryButtonStyle(phase: phase, large: true))
                    .accessibilityIdentifier("timer.confirmAdvanceButton")

                    Button("重置本轮") {
                        viewModel.showResetConfirm = true
                    }
                    .buttonStyle(TomatoTimerSecondaryButtonStyle(phase: phase, enabled: true))
                    .accessibilityIdentifier("timer.resetButtonAwaiting")
                }
            } else {
                HStack(spacing: 12) {
                    Button(
                        viewModel.engine.runState == .running
                            ? "暂停"
                            : (viewModel.engine.runState == .paused ? "继续" : "开始")
                    ) {
                        if viewModel.engine.runState == .idle {
                            viewModel.start()
                        } else {
                            viewModel.togglePauseResume()
                        }
                    }
                    .keyboardShortcut(.space, modifiers: [])
                    .buttonStyle(TomatoTimerPrimaryButtonStyle(phase: phase, large: false))
                    .accessibilityIdentifier("timer.startPauseButton")

                    Button("跳过") {
                        viewModel.skip()
                    }
                    .disabled(!secondaryActionEnabled)
                    .buttonStyle(TomatoTimerSecondaryButtonStyle(phase: phase, enabled: secondaryActionEnabled))
                    .accessibilityIdentifier("timer.skipButton")

                    Button("重置本轮") {
                        viewModel.showResetConfirm = true
                    }
                    .disabled(!secondaryActionEnabled)
                    .buttonStyle(TomatoTimerSecondaryButtonStyle(phase: phase, enabled: secondaryActionEnabled))
                    .accessibilityIdentifier("timer.resetButton")
                }
            }
        }
        .confirmationDialog("确定重置本轮？", isPresented: $viewModel.showResetConfirm, titleVisibility: .visible) {
            Button("重置", role: .destructive) {
                viewModel.confirmResetRound()
            }
            Button("取消", role: .cancel) {}
        }
    }
}

private struct TomatoTimerPrimaryButtonStyle: ButtonStyle {
    let phase: PomodoroPhase
    var large: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundColor(TomatoPalette.timerPrimaryLabel(for: phase))
            .padding(.horizontal, large ? 22 : 16)
            .padding(.vertical, large ? 11 : 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(TomatoPalette.timerPrimaryFill(for: phase))
            )
            .opacity(configuration.isPressed ? 0.88 : 1)
    }
}

private struct TomatoTimerSecondaryButtonStyle: ButtonStyle {
    let phase: PomodoroPhase
    var enabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .foregroundColor(Color.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(TomatoPalette.timerSecondaryFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(TomatoPalette.timerSecondaryStroke(for: phase), lineWidth: 1)
            )
            .opacity(enabled ? (configuration.isPressed ? 0.88 : 1) : 0.42)
    }
}
