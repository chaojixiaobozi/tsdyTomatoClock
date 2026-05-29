import XCTest
@testable import TomatoClock

final class PomodoroPersistenceTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var persistence: PomodoroPersistence!

    override func setUp() {
        super.setUp()
        suiteName = "PomodoroPersistenceTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        persistence = PomodoroPersistence(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        persistence = nil
        suiteName = nil
        super.tearDown()
    }

    func testSaveSyncsTodayIntoHistory() {
        persistence.save(config: .default, calendarDay: "2026-05-18", todayCount: 3)
        let history = persistence.loadDailyHistory()
        XCTAssertEqual(history["2026-05-18"], 3)
    }

    func testSaveDoesNotStoreZeroInHistory() {
        persistence.save(config: .default, calendarDay: "2026-05-18", todayCount: 0)
        XCTAssertTrue(persistence.loadDailyHistory().isEmpty)
    }

    func testLoadBootstrapArchivesPreviousDayWhenDayChanges() {
        persistence.save(config: .default, calendarDay: "2026-05-18", todayCount: 4)
        let (_, count) = persistence.loadBootstrap(for: "2026-05-19")
        XCTAssertEqual(count, 0)
        XCTAssertEqual(persistence.loadDailyHistory()["2026-05-18"], 4)
    }

    func testArchiveDayIfNeededOnlyWhenPositive() {
        persistence.archiveDayIfNeeded(storedDay: "2026-05-17", count: 0)
        persistence.archiveDayIfNeeded(storedDay: "2026-05-18", count: 2)
        let history = persistence.loadDailyHistory()
        XCTAssertNil(history["2026-05-17"])
        XCTAssertEqual(history["2026-05-18"], 2)
    }

    func testRecordDayUpsertsAndRemovesOnZero() {
        persistence.recordDay("2026-05-18", count: 5)
        persistence.recordDay("2026-05-18", count: 0)
        XCTAssertNil(persistence.loadDailyHistory()["2026-05-18"])
    }

    func testCountPrefersTodayCountOverHistory() {
        let history = ["2026-05-29": 1]
        XCTAssertEqual(
            PomodoroPersistence.count(
                for: "2026-05-29",
                in: history,
                todayDay: "2026-05-29",
                todayCount: 3
            ),
            3
        )
    }

    func testCountReturnsNilForEmptyDays() {
        XCTAssertNil(
            PomodoroPersistence.count(
                for: "2026-05-01",
                in: [:],
                todayDay: "2026-05-29",
                todayCount: 0
            )
        )
    }
}
