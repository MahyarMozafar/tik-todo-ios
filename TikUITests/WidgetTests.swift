import XCTest

/// Adds the Today widget to the Home Screen and checks that it shows the
/// same tasks as the app (so the App Group sharing works).
///
/// It changes the simulator's Home Screen and takes about a minute, so it
/// only runs when TEST_RUNNER_RUN_WIDGET_TESTS=1 is set.
final class WidgetTests: XCTestCase {
    private let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    override func setUpWithError() throws {
        continueAfterFailure = false
        try XCTSkipUnless(ProcessInfo.processInfo.environment["RUN_WIDGET_TESTS"] == "1",
                          "Set TEST_RUNNER_RUN_WIDGET_TESTS=1 to run the widget tests.")
    }

    func testWidgetsShowTodaysTasks() throws {
        let app = XCUIApplication.demo()
        app.launch()
        sleep(2)
        XCUIDevice.shared.press(.home)

        try addTikWidget(swipesToSize: 1)   // medium
        try addTikWidget(swipesToSize: 2)   // large

        XCTAssertTrue(springboard.staticTexts["Pay the internet bill"].waitForExistence(timeout: 10))
        XCTAssertTrue(springboard.buttons["Mark as Done"].exists)
        Screenshot.save("widgets")
    }

    /// Opens the widget gallery, finds Tik, swipes to a size and adds it.
    private func addTikWidget(swipesToSize swipes: Int) throws {
        let names = ["Settings", "Safari", "Photos", "Calendar", "Tik"]
        let icon = try XCTUnwrap(names.lazy.map { self.springboard.icons[$0] }.first { $0.exists && $0.isHittable },
                                 "No app icon to long-press")
        icon.press(forDuration: 1.2)

        let editHomeScreen = springboard.buttons["Edit Home Screen"]
        if editHomeScreen.waitForExistence(timeout: 3) {
            editHomeScreen.tap()
        }

        // The button's label starts with an icon, so match on "contains".
        let addWidget = springboard.buttons.matching(NSPredicate(format: "label CONTAINS 'Add Widget'")).firstMatch
        let edit = springboard.buttons["Edit"]
        if edit.waitForExistence(timeout: 3) {
            edit.tap()
        }
        XCTAssertTrue(addWidget.waitForExistence(timeout: 3))
        addWidget.tap()

        let search = springboard.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("Tik")

        let result = springboard.cells.matching(NSPredicate(format: "label BEGINSWITH 'Tik'")).firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 5))
        result.tap()

        sleep(1)
        for _ in 0..<swipes {
            springboard.swipeLeft()
            sleep(1)
        }
        let add = springboard.buttons.matching(NSPredicate(format: "label CONTAINS 'Add Widget'")).firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        add.tap()
        sleep(1)

        let done = springboard.buttons["Done"]
        if done.waitForExistence(timeout: 3) {
            done.tap()
        }
        sleep(2)
    }
}
