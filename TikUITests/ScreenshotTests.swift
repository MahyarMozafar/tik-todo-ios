import XCTest

/// Walks through the main screens and saves screenshots (for the README).
/// Run with TEST_RUNNER_SCREENSHOTS_DIR=<folder> to keep the images.
final class ScreenshotTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testEnglishLight() {
        capture(language: "en", theme: "light", prefix: "en-light")
    }

    func testEnglishDark() {
        capture(language: "en", theme: "dark", prefix: "en-dark")
    }

    func testFarsiLight() {
        capture(language: "fa", theme: "light", prefix: "fa-light")
    }

    func testFarsiDark() {
        capture(language: "fa", theme: "dark", prefix: "fa-dark")
    }

    private func capture(language: String, theme: String, prefix: String) {
        let app = XCUIApplication.demo(language: language, theme: theme)
        app.launch()
        XCTAssertTrue(app.buttons["quickAddButton"].waitForExistence(timeout: 5))
        Screenshot.save("\(prefix)-today")

        // The task editor, opened on "Buy groceries".
        app.staticTexts.matching(identifier: "taskTitle").element(boundBy: 4).tap()
        XCTAssertTrue(app.buttons["saveButton"].waitForExistence(timeout: 3))
        Screenshot.save("\(prefix)-editor")
        app.buttons["cancelButton"].tap()

        // Lists, then the Scheduled smart list.
        app.tabBars.buttons.element(boundBy: 1).tap()
        XCTAssertTrue(app.buttons["newListButton"].waitForExistence(timeout: 3))
        Screenshot.save("\(prefix)-lists")
        app.buttons["smart-scheduled"].tap()
        sleep(1)
        Screenshot.save("\(prefix)-scheduled")

        // Settings, from Today.
        app.tabBars.buttons.element(boundBy: 0).tap()
        app.buttons["settingsButton"].tap()
        XCTAssertTrue(app.buttons["closeSettings"].waitForExistence(timeout: 3))
        Screenshot.save("\(prefix)-settings")
        app.buttons["closeSettings"].tap()

        // The quick add field, open.
        app.buttons["quickAddButton"].tap()
        XCTAssertTrue(app.textFields["quickAddField"].waitForExistence(timeout: 3))
        sleep(1)
        Screenshot.save("\(prefix)-quick-add")
    }
}
