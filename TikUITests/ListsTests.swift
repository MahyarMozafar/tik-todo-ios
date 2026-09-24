import XCTest

final class ListsTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testCreateListAndAddTaskToIt() {
        let app = XCUIApplication.demo()
        app.launch()

        app.tabBars.buttons["Lists"].tap()
        XCTAssertTrue(app.buttons["newListButton"].waitForExistence(timeout: 3))
        Screenshot.save("lists")

        app.buttons["newListButton"].tap()
        let name = app.textFields["listNameField"]
        XCTAssertTrue(name.waitForExistence(timeout: 3))
        name.typeText("Travel")
        app.buttons["saveListButton"].tap()

        app.staticTexts["Travel"].tap()
        app.buttons["quickAddButton"].tap()
        app.textFields["quickAddField"].typeText("Pack the bags\n")
        XCTAssertTrue(app.staticTexts["Pack the bags"].waitForExistence(timeout: 3))
    }

    func testScheduledShowsUpcomingTasksByDay() {
        let app = XCUIApplication.demo()
        app.launch()

        app.tabBars.buttons["Lists"].tap()
        app.buttons["smart-scheduled"].tap()

        XCTAssertTrue(app.staticTexts["Team meeting"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Tomorrow"].exists)
        Screenshot.save("scheduled")
    }
}
