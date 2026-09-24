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

final class AppIconTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testChangingTheAppIcon() {
        let app = XCUIApplication.demo()
        app.launch()

        app.buttons["settingsButton"].tap()
        let row = app.buttons["App Icon"]
        for _ in 0..<4 where !row.isHittable {
            app.swipeUp()
        }
        row.tap()

        app.buttons["Mint"].tap()
        dismissIconAlert(in: app)
        Screenshot.save("app-icon")

        // Put the main icon back.
        app.buttons["Blue"].tap()
        dismissIconAlert(in: app)
    }

    /// iOS says "You have changed the icon for Tik." after every change.
    private func dismissIconAlert(in app: XCUIApplication) {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for alerts in [app.alerts, springboard.alerts] {
            let button = alerts.buttons.firstMatch
            if button.waitForExistence(timeout: 2) {
                button.tap()
                return
            }
        }
    }
}
