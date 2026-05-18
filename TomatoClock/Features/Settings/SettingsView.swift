import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: TimerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("时长（分钟）") {
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
                Section("轮次") {
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
                Section {
                    Text("仅在「空闲」时保存会立即生效；计时中请暂停或结束后再改。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("设置")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                        .accessibilityIdentifier("settings.closeButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        viewModel.applySettingsIfPossible()
                        dismiss()
                    }
                    .disabled(viewModel.engine.runState != .idle)
                    .accessibilityIdentifier("settings.saveButton")
                }
            }
        }
        .frame(minWidth: 420, minHeight: 360)
        .onAppear {
            viewModel.configDraft = viewModel.engine.config
        }
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
