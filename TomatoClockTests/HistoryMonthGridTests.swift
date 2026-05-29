import XCTest
@testable import TomatoClock

final class HistoryMonthGridTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        cal.firstWeekday = 2
        cal.locale = Locale(identifier: "zh_CN")
        calendar = cal
    }

    func testMay2026GridHasCorrectDayCount() {
        let grid = HistoryMonthGridBuilder.build(
            year: 2026,
            month: 5,
            todayDay: "2026-05-29",
            todayCount: 2,
            history: ["2026-05-18": 4],
            calendar: calendar
        )
        XCTAssertEqual(grid.year, 2026)
        XCTAssertEqual(grid.month, 5)
        XCTAssertEqual(grid.cells.count % 7, 0)

        let inMonth = grid.cells.filter(\.isInCurrentMonth)
        XCTAssertEqual(inMonth.count, 31)
    }

    func testGridShowsHistoryAndTodayCounts() {
        let grid = HistoryMonthGridBuilder.build(
            year: 2026,
            month: 5,
            todayDay: "2026-05-29",
            todayCount: 2,
            history: ["2026-05-18": 4],
            calendar: calendar
        )

        let day18 = grid.cells.first { $0.calendarDay == "2026-05-18" }
        let day29 = grid.cells.first { $0.calendarDay == "2026-05-29" }
        let day01 = grid.cells.first { $0.calendarDay == "2026-05-01" }

        XCTAssertEqual(day18?.count, 4)
        XCTAssertEqual(day29?.count, 2)
        XCTAssertTrue(day29?.isToday == true)
        XCTAssertNil(day01?.count)
    }

    func testAdjacentMonthWrapsYear() {
        let prev = HistoryMonthGridBuilder.adjacentMonth(year: 2026, month: 1, delta: -1)
        XCTAssertEqual(prev.year, 2025)
        XCTAssertEqual(prev.month, 12)
        let next = HistoryMonthGridBuilder.adjacentMonth(year: 2026, month: 12, delta: 1)
        XCTAssertEqual(next.year, 2027)
        XCTAssertEqual(next.month, 1)
    }

    func testWeekdayHeadersHasSevenSymbols() {
        let grid = HistoryMonthGridBuilder.build(
            year: 2026,
            month: 5,
            todayDay: "2026-05-29",
            todayCount: 0,
            history: [:],
            calendar: calendar
        )
        XCTAssertEqual(grid.weekdayHeaders.count, 7)
        XCTAssertEqual(Set(grid.weekdayHeaders).count, 7)
    }
}
