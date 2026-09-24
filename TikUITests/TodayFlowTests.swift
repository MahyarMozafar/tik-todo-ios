import XCTest

final class TodayFlowTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testQuickAddKeepsFieldOpenForTheNextTask() {
        let app = XCUIApplication.demo()
        app.launch()

        app.buttons["quickAddButton"].tap()
        let field = app.textFields["quickAddField"]
        XCTAssertTrue(field.waitForExistence(timeout: 3))

        field.typeText("Buy flowers\n")
        XCTAssertTrue(app.staticTexts["Buy flowers"].waitForExistence(timeout: 3))
        Screenshot.save("quick-add")

        // The field stays open, so the next task can be typed right away.
        field.typeText("Call Ali\n")
        XCTAssertTrue(app.staticTexts["Call Ali"].waitForExistence(timeout: 3))
    }

    func testTickingMovesTaskToTheBottom() {
        let app = XCUIApplication.demo()
        app.launch()

        let title = app.staticTexts["Call mom"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))
        let startY = title.frame.minY

        app.buttons["check-Call mom"].tap()

        // After the check animation the task moves below the open ones.
        let moved = expectation(for: NSPredicate { _, _ in title.frame.minY > startY + 1 }, evaluatedWith: nil)
        wait(for: [moved], timeout: 4)
    }
}

extension XCUIApplication {
    /// The app filled with example tasks, in English, light mode.
    static func demo(language: String = "en", theme: String = "light", extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-lang", language, "-theme", theme] + extra
        return app
    }
}

/// Saves a screenshot to the folder in the SCREENSHOTS_DIR environment
/// variable (pass it as TEST_RUNNER_SCREENSHOTS_DIR to xcodebuild).
enum Screenshot {
    static func save(_ name: String) {
        guard let folder = ProcessInfo.processInfo.environment["SCREENSHOTS_DIR"] else { return }
        let data = XCUIScreen.main.screenshot().pngRepresentation
        try? data.write(to: URL(fileURLWithPath: folder).appendingPathComponent("\(name).png"))
    }
}

final class CelebrationTests: XCTestCase {
    func testTickingTheLastTaskOfTheDayShowsConfetti() {
        let app = XCUIApplication.demo()
        app.launch()

        let open = ["Pay the internet bill", "Reply to Sara's email", "Call mom", "Buy groceries", "Read 20 pages"]
        for title in open {
            let check = app.buttons["check-\(title)"]
            XCTAssertTrue(check.waitForExistence(timeout: 3))
            check.tap()
            sleep(1)
        }

        XCTAssertTrue(app.staticTexts["All done for today!"].waitForExistence(timeout: 3))
        Screenshot.save("all-done")
    }
}
