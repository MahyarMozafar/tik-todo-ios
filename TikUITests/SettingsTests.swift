import XCTest

final class SettingsTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testOpenSettingsAndTurnOffProgress() {
        let app = XCUIApplication.demo()
        app.launch()

        app.buttons["settingsButton"].tap()
        XCTAssertTrue(app.buttons["closeSettings"].waitForExistence(timeout: 3))
        Screenshot.save("settings")

        let progress = app.switches["Show Progress"]
        for _ in 0..<4 where !progress.isHittable {
            app.swipeUp()
        }
        progress.switches.firstMatch.tap()
        app.buttons["closeSettings"].tap()

        XCTAssertFalse(app.staticTexts["2 of 7 done"].waitForExistence(timeout: 2))
    }
}
