import XCTest

final class TomatoClockUITests: XCTestCase {
    func testLaunchShowsTimerChrome() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["TsdyTomatoClock"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(identifier: "timer.remainingLabel").firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(identifier: "timer.phaseLabel").firstMatch.exists)
        XCTAssertTrue(app.buttons.matching(identifier: "timer.startPauseButton").firstMatch.exists)
        XCTAssertTrue(app.buttons.matching(identifier: "timer.settingsButton").firstMatch.exists)
    }

    func testOpenSettingsAndClose() {
        let app = XCUIApplication()
        app.launch()

        app.buttons.matching(identifier: "timer.settingsButton").firstMatch.tap()
        XCTAssertTrue(app.buttons.matching(identifier: "settings.closeButton").firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons.matching(identifier: "settings.preset.classic255").firstMatch.exists)
        app.buttons.matching(identifier: "settings.closeButton").firstMatch.tap()
        XCTAssertTrue(app.buttons.matching(identifier: "timer.settingsButton").firstMatch.waitForExistence(timeout: 5))
    }
}
