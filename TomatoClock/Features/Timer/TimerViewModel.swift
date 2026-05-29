import Combine
import Foundation
import SwiftUI

@MainActor
final class TimerViewModel: ObservableObject {
    @Published private(set) var engine: PomodoroEngine
    @Published var configDraft: PomodoroConfig
    @Published var showResetConfirm = false
    @Published private(set) var notificationDenied: Bool = false
    @Published private(set) var lastAppliedPreset: PomodoroPreset?

    private let persistence: PomodoroPersistence
    private let notifications: PomodoroNotificationService
    private var ticker: AnyCancellable?

    init(
        persistence: PomodoroPersistence = .shared,
        notifications: PomodoroNotificationService = .shared
    ) {
        self.persistence = persistence
        self.notifications = notifications
        let day = PomodoroPersistence.todayString()
        let (cfg, count) = persistence.loadBootstrap(for: day)
        var e = PomodoroEngine(config: cfg, calendarDay: day)
        e.setTodayCompleted(count, calendarDay: day)
        self.engine = e
        self.configDraft = cfg
        self.lastAppliedPreset = persistence.loadLastPreset()
        startTicker()
        persist()
        Task { await refreshNotificationFlag() }
    }

    private func startTicker() {
        ticker?.cancel()
        ticker = Timer.publish(every: 0.25, tolerance: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func tick() {
        let day = PomodoroPersistence.todayString()
        let previous = engine
        var e = engine

        if day != previous.currentCalendarDay {
            persistence.archiveDayIfNeeded(
                storedDay: previous.currentCalendarDay,
                count: previous.todayCompletedPomodoros
            )
        }

        e.rolloverCalendarDayIfNeeded(calendarDay: day)
        let rolled = e.currentCalendarDay != previous.currentCalendarDay

        if e.runState == .running {
            let now = Date()
            if e.remainingSeconds(at: now) == 0 {
                e.completeCurrentSegmentNaturally(at: now)
                engine = e
                persist()
                notifications.cancelAll()
                MainWindowHolder.shared.bringForward()
                return
            }
        }

        engine = e
        if rolled {
            persist()
        }
    }

    func requestNotifications() {
        Task {
            await notifications.requestAuthorization()
            await refreshNotificationFlag()
        }
    }

    private func refreshNotificationFlag() async {
        await notifications.refreshAuthorizationStatus()
        notificationDenied = notifications.authorizationDenied
    }

    func start() {
        var e = engine
        let now = Date()
        e.start(at: now)
        engine = e
        persist()
        rescheduleNotification()
    }

    func confirmAdvance() {
        var e = engine
        e.confirmAdvance(at: Date())
        engine = e
        persist()
        rescheduleNotification()
    }

    func togglePauseResume() {
        var e = engine
        let now = Date()
        switch e.runState {
        case .running:
            e.pause(at: now)
            notifications.cancelAll()
        case .paused:
            e.resume(at: now)
            rescheduleNotification()
        case .idle, .awaitingAdvance:
            break
        }
        engine = e
        persist()
    }

    func skip() {
        var e = engine
        e.skipCurrentSegment(at: Date())
        engine = e
        persist()
        rescheduleNotification()
    }

    func confirmResetRound() {
        var e = engine
        e.resetRound()
        engine = e
        notifications.cancelAll()
        persist()
        showResetConfirm = false
    }

    /// 可切换时长预设：空闲，或本段已结束、待确认进入下一段（尚未开始新段计时）。
    var allowsPresetChange: Bool {
        switch engine.runState {
        case .idle, .awaitingAdvance: return true
        case .running, .paused: return false
        }
    }

    func applySettingsIfPossible() {
        guard engine.runState == .idle else { return }
        var e = engine
        e.updateConfig(configDraft)
        engine = e
        lastAppliedPreset = Self.matchingPreset(for: configDraft)
        persist()
    }

    func applyPreset(_ preset: PomodoroPreset) {
        guard allowsPresetChange else { return }
        let cfg = preset.config
        var e = engine
        e.updateConfig(cfg)
        engine = e
        configDraft = cfg
        lastAppliedPreset = preset
        persist()
    }

    private func persist() {
        persistence.save(
            config: engine.config,
            calendarDay: engine.currentCalendarDay,
            todayCount: engine.todayCompletedPomodoros,
            lastPreset: lastAppliedPreset
        )
    }

    func dailyHistorySnapshot() -> (todayDay: String, todayCount: Int, history: [String: Int]) {
        (
            engine.currentCalendarDay,
            engine.todayCompletedPomodoros,
            persistence.loadDailyHistory()
        )
    }

    private func rescheduleNotification() {
        Task { await refreshNotificationFlag() }
        guard engine.runState == .running else {
            notifications.cancelAll()
            return
        }
        let secs = engine.remainingSeconds(at: Date())
        notifications.schedulePhaseEnd(phase: engine.phase, remainingSeconds: secs)
    }

    func formattedRemaining() -> String {
        if engine.runState == .awaitingAdvance {
            return "--:--"
        }
        let s = engine.remainingSeconds(at: Date())
        let m = s / 60
        let r = s % 60
        return String(format: "%02d:%02d", m, r)
    }

    func phaseHeadline() -> String {
        if engine.runState == .awaitingAdvance {
            return "本阶段已结束 · 下一阶段：\(engine.phase.displayTitle)"
        }
        return engine.phase.displayTitle
    }

    static func matchingPreset(for config: PomodoroConfig) -> PomodoroPreset? {
        for preset in PomodoroPreset.allCases {
            let c = preset.config
            if durationsEqual(c, config) { return preset }
        }
        return nil
    }

    private static func durationsEqual(_ a: PomodoroConfig, _ b: PomodoroConfig) -> Bool {
        abs(a.workDuration - b.workDuration) < 0.5
            && abs(a.shortBreakDuration - b.shortBreakDuration) < 0.5
            && abs(a.longBreakDuration - b.longBreakDuration) < 0.5
            && a.pomodorosUntilLongBreak == b.pomodorosUntilLongBreak
    }
}
