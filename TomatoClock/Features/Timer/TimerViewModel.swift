import Combine
import Foundation
import SwiftUI

@MainActor
final class TimerViewModel: ObservableObject {
    @Published private(set) var engine: PomodoroEngine
    @Published var configDraft: PomodoroConfig
    @Published var showResetConfirm = false
    @Published private(set) var notificationDenied: Bool = false

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
        e.rolloverCalendarDayIfNeeded(calendarDay: day)
        let rolled = e.currentCalendarDay != previous.currentCalendarDay

        if e.runState == .running {
            let now = Date()
            if e.remainingSeconds(at: now) == 0 {
                e.acknowledgeSegmentComplete(at: now, naturalCompletion: true)
                engine = e
                persist()
                rescheduleNotification()
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
        case .idle:
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

    func applySettingsIfPossible() {
        guard engine.runState == .idle else { return }
        var e = engine
        e.updateConfig(configDraft)
        engine = e
        persist()
    }

    private func persist() {
        persistence.save(
            config: engine.config,
            calendarDay: engine.currentCalendarDay,
            todayCount: engine.todayCompletedPomodoros
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
        let s = engine.remainingSeconds(at: Date())
        let m = s / 60
        let r = s % 60
        return String(format: "%02d:%02d", m, r)
    }
}
