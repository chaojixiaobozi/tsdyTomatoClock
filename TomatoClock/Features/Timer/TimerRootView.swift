import SwiftUI

struct TimerRootView: View {
    @StateObject private var viewModel = TimerViewModel()
    @State private var showSettings = false

    var body: some View {
        ZStack {
            TomatoPalette.background(for: viewModel.engine.phase, runState: viewModel.engine.runState)
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
        .frame(minWidth: 360, minHeight: 420)
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.requestNotifications()
        }
    }

    private var header: some View {
        HStack {
            Text("番茄钟")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
            Spacer()
            Button("设置") {
                showSettings = true
            }
            .accessibilityIdentifier("timer.settingsButton")
        }
    }

    private var phaseLabel: some View {
        Text(viewModel.engine.phase.displayTitle)
            .font(.title3)
            .foregroundStyle(.secondary)
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

    private var controls: some View {
        VStack(spacing: 12) {
            if viewModel.notificationDenied {
                Text("未开启通知权限，阶段结束时可能收不到系统提醒。可在「系统设置 → 通知」中开启。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("timer.notificationHint")
            }

            HStack(spacing: 12) {
                Button(viewModel.engine.runState == .running ? "暂停" : (viewModel.engine.runState == .paused ? "继续" : "开始")) {
                    if viewModel.engine.runState == .idle {
                        viewModel.start()
                    } else {
                        viewModel.togglePauseResume()
                    }
                }
                .keyboardShortcut(.space, modifiers: [])
                .buttonStyle(.borderedProminent)
                .tint(TomatoPalette.workAccent)
                .accessibilityIdentifier("timer.startPauseButton")

                Button("跳过") {
                    viewModel.skip()
                }
                .disabled(viewModel.engine.runState == .idle)
                .accessibilityIdentifier("timer.skipButton")

                Button("重置本轮") {
                    viewModel.showResetConfirm = true
                }
                .disabled(viewModel.engine.runState == .idle)
                .accessibilityIdentifier("timer.resetButton")
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
