import Foundation

/// 本地持久化：配置 + 当日完成数 + 按日历史（按自然日字符串对齐）。
public struct PomodoroPersistence: Sendable {
    public static let shared = PomodoroPersistence()

    private let defaults: UserDefaults
    private let keyConfig = "pomodoro.config.v1"
    private let keyDay = "pomodoro.calendarDay.v1"
    private let keyTodayCount = "pomodoro.todayCount.v1"
    private let keyLastPreset = "pomodoro.lastPreset.v1"
    private let keyDailyHistory = "pomodoro.dailyHistory.v1"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// 读取配置与「存储日」下的完成数；若存储日与 `calendarDay` 不一致则归档旧日并返回计数 0。
    public func loadBootstrap(for calendarDay: String) -> (PomodoroConfig, Int) {
        let config = loadConfig()
        guard let storedDay = defaults.string(forKey: keyDay) else {
            return (config, 0)
        }
        if storedDay != calendarDay {
            let storedCount = defaults.integer(forKey: keyTodayCount)
            archiveDayIfNeeded(storedDay: storedDay, count: storedCount)
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

    public func loadLastPreset() -> PomodoroPreset? {
        guard let raw = defaults.string(forKey: keyLastPreset) else { return nil }
        return PomodoroPreset(rawValue: raw)
    }

    public func loadDailyHistory() -> [String: Int] {
        guard let data = defaults.data(forKey: keyDailyHistory),
              let decoded = try? JSONDecoder().decode([String: Int].self, from: data)
        else {
            return [:]
        }
        return decoded
    }

    public func save(config: PomodoroConfig, calendarDay: String, todayCount: Int, lastPreset: PomodoroPreset? = nil) {
        if let data = try? JSONEncoder().encode(config) {
            defaults.set(data, forKey: keyConfig)
        }
        defaults.set(calendarDay, forKey: keyDay)
        defaults.set(todayCount, forKey: keyTodayCount)
        if let lastPreset {
            defaults.set(lastPreset.rawValue, forKey: keyLastPreset)
        }
        syncHistory(calendarDay: calendarDay, todayCount: todayCount)
    }

    /// 跨日或启动时发现存储日变化：将上一日完成数写入历史（仅 count > 0）。
    public func archiveDayIfNeeded(storedDay: String, count: Int) {
        guard count > 0 else { return }
        recordDay(storedDay, count: count)
    }

    /// upsert 单日完成数；count <= 0 时移除该键。
    public func recordDay(_ calendarDay: String, count: Int) {
        var history = loadDailyHistory()
        if count > 0 {
            history[calendarDay] = count
        } else {
            history.removeValue(forKey: calendarDay)
        }
        writeDailyHistory(history)
    }

    /// 查询某日完成数：`todayDay` 优先返回内存中的 `todayCount`，否则读历史字典。
    public static func count(
        for calendarDay: String,
        in history: [String: Int],
        todayDay: String,
        todayCount: Int
    ) -> Int? {
        if calendarDay == todayDay {
            return todayCount > 0 ? todayCount : nil
        }
        guard let value = history[calendarDay], value > 0 else { return nil }
        return value
    }

    public static func todayString(for date: Date = Date(), calendar: Calendar = .current) -> String {
        let c = calendar
        let comps = c.dateComponents([.year, .month, .day], from: date)
        let y = comps.year ?? 0
        let m = comps.month ?? 0
        let d = comps.day ?? 0
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    private func syncHistory(calendarDay: String, todayCount: Int) {
        var history = loadDailyHistory()
        if todayCount > 0 {
            history[calendarDay] = todayCount
        } else {
            history.removeValue(forKey: calendarDay)
        }
        writeDailyHistory(history)
    }

    private func writeDailyHistory(_ history: [String: Int]) {
        if let data = try? JSONEncoder().encode(history) {
            defaults.set(data, forKey: keyDailyHistory)
        }
    }
}
