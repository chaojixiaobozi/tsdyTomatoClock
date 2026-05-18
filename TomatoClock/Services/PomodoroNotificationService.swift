import Foundation
import UserNotifications

@MainActor
public final class PomodoroNotificationService: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    public static let shared = PomodoroNotificationService()

    @Published public private(set) var authorizationDenied: Bool = false

    private let center = UNUserNotificationCenter.current()

    public override init() {
        super.init()
        center.delegate = self
    }

    public func requestAuthorization() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            authorizationDenied = !granted
        } catch {
            authorizationDenied = true
        }
    }

    public func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .denied, .ephemeral:
            authorizationDenied = true
        default:
            authorizationDenied = false
        }
    }

    public func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    /// 为当前阶段剩余时间调度一条本地通知（开始 / 恢复时调用）。
    public func schedulePhaseEnd(phase: PomodoroPhase, remainingSeconds: Int) {
        cancelAll()
        guard remainingSeconds > 1 else { return }
        let content = UNMutableNotificationContent()
        content.title = "TsdyTomatoClock"
        content.body = phaseEndBody(for: phase)
        content.sound = UNNotificationSound.default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(remainingSeconds), repeats: false)
        let id = "pomodoro.phaseEnd"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request, withCompletionHandler: nil)
    }

    private func phaseEndBody(for phase: PomodoroPhase) -> String {
        switch phase {
        case .work: return "专注阶段结束，休息一下。"
        case .shortBreak: return "短休结束，继续专注。"
        case .longBreak: return "长休结束，继续专注。"
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
