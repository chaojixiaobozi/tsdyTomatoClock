import Foundation

struct HistoryDayCell: Equatable, Sendable {
    let calendarDay: String?
    let dayOfMonth: Int?
    let count: Int?
    let isToday: Bool
    let isInCurrentMonth: Bool
}

struct HistoryMonthGrid: Equatable, Sendable {
    let year: Int
    let month: Int
    let title: String
    let weekdayHeaders: [String]
    let cells: [HistoryDayCell]
}

enum HistoryMonthGridBuilder {
    static func build(
        year: Int,
        month: Int,
        todayDay: String,
        todayCount: Int,
        history: [String: Int],
        calendar: Calendar = .current
    ) -> HistoryMonthGrid {
        var cal = calendar
        cal.locale = calendar.locale ?? Locale.current

        var monthComponents = DateComponents()
        monthComponents.year = year
        monthComponents.month = month
        monthComponents.day = 1
        guard let firstOfMonth = cal.date(from: monthComponents),
              let dayRange = cal.range(of: .day, in: .month, for: firstOfMonth)
        else {
            return HistoryMonthGrid(
                year: year,
                month: month,
                title: "\(year) 年 \(month) 月",
                weekdayHeaders: weekdayHeaders(calendar: cal),
                cells: []
            )
        }

        let daysInMonth = dayRange.count
        let firstWeekday = cal.component(.weekday, from: firstOfMonth)
        let leading = (firstWeekday - cal.firstWeekday + 7) % 7
        let totalCells = ((leading + daysInMonth + 6) / 7) * 7

        var cells: [HistoryDayCell] = []
        cells.reserveCapacity(totalCells)

        for index in 0..<totalCells {
            let dayNumber = index - leading + 1
            if dayNumber < 1 || dayNumber > daysInMonth {
                cells.append(
                    HistoryDayCell(
                        calendarDay: nil,
                        dayOfMonth: nil,
                        count: nil,
                        isToday: false,
                        isInCurrentMonth: false
                    )
                )
                continue
            }

            var dayComponents = DateComponents()
            dayComponents.year = year
            dayComponents.month = month
            dayComponents.day = dayNumber
            let dayString = PomodoroPersistence.todayString(
                for: cal.date(from: dayComponents) ?? firstOfMonth,
                calendar: cal
            )
            let count = PomodoroPersistence.count(
                for: dayString,
                in: history,
                todayDay: todayDay,
                todayCount: todayCount
            )
            cells.append(
                HistoryDayCell(
                    calendarDay: dayString,
                    dayOfMonth: dayNumber,
                    count: count,
                    isToday: dayString == todayDay,
                    isInCurrentMonth: true
                )
            )
        }

        let formatter = DateFormatter()
        formatter.locale = cal.locale
        formatter.dateFormat = "yyyy 年 M 月"
        let title = formatter.string(from: firstOfMonth)

        return HistoryMonthGrid(
            year: year,
            month: month,
            title: title,
            weekdayHeaders: weekdayHeaders(calendar: cal),
            cells: cells
        )
    }

    static func currentYearMonth(calendar: Calendar = .current) -> (year: Int, month: Int) {
        let now = Date()
        return (
            calendar.component(.year, from: now),
            calendar.component(.month, from: now)
        )
    }

    static func adjacentMonth(year: Int, month: Int, delta: Int) -> (year: Int, month: Int) {
        var y = year
        var m = month + delta
        while m < 1 {
            m += 12
            y -= 1
        }
        while m > 12 {
            m -= 12
            y += 1
        }
        return (y, m)
    }

    private static func weekdayHeaders(calendar: Calendar) -> [String] {
        let symbols = calendar.shortWeekdaySymbols
        let start = calendar.firstWeekday - 1
        return (0..<7).map { symbols[(start + $0) % 7] }
    }
}
