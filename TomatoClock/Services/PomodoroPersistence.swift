import Foundation

/// 本地持久化：配置 + 当日完成数（按自然日字符串对齐）。
public struct PomodoroPersistence: Sendable {
    public static let shared = PomodoroPersistence()

    private let defaults: UserDefaults
    private let keyConfig = "pomodoro.config.v1"
    private let keyDay = "pomodoro.calendarDay.v1"
    private let keyTodayCount = "pomodoro.todayCount.v1"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// 读取配置与「存储日」下的完成数；若存储日与 `calendarDay` 不一致则返回计数 0（新一天）。
    public func loadBootstrap(for calendarDay: String) -> (PomodoroConfig, Int) {
        let config = loadConfig()
        guard defaults.string(forKey: keyDay) == calendarDay else {
            return (config, 0)
        }
        return (config, defaults.integer(forKey: keyTodayCount))
    }

    public func loadConfig() -> PomodoroConfig {
        guard let data = defaults.data(forKey: keyConfig),
              let decoded = try? JSONDecoder().decode(PomodoroConfig.self, from: data)
        else {
            return .default
        }
        return decoded
    }

    public func save(config: PomodoroConfig, calendarDay: String, todayCount: Int) {
        if let data = try? JSONEncoder().encode(config) {
            defaults.set(data, forKey: keyConfig)
        }
        defaults.set(calendarDay, forKey: keyDay)
        defaults.set(todayCount, forKey: keyTodayCount)
    }

    public static func todayString(for date: Date = Date(), calendar: Calendar = .current) -> String {
        let c = calendar
        let comps = c.dateComponents([.year, .month, .day], from: date)
        let y = comps.year ?? 0
        let m = comps.month ?? 0
        let d = comps.day ?? 0
        return String(format: "%04d-%02d-%02d", y, m, d)
    }
}
