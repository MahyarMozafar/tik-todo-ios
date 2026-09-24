import XCTest

final class SearchTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testFindsTasksBySubtask() {
        let app = XCUIApplication.demo()
        app.launch()

        app.tabBars.buttons["Search"].tap()
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        field.tap()
        field.typeText("eggs")

        // "Eggs" is a subtask of "Buy groceries".
        XCTAssertTrue(app.staticTexts["Buy groceries"].waitForExistence(timeout: 3))
        Screenshot.save("search")
    }
}
