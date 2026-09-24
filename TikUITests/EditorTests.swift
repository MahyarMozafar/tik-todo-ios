import XCTest

final class EditorTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testEditTaskAndAddSubtask() {
        let app = XCUIApplication.demo()
        app.launch()

        app.staticTexts["Buy groceries"].tap()
        let title = app.textFields["titleField"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))
        Screenshot.save("editor")

        let addSubtask = app.buttons["Add Subtask"]
        for _ in 0..<5 where !addSubtask.isHittable {
            app.swipeUp()
        }
        addSubtask.tap()
        app.typeText("Butter\n")
        app.buttons["saveButton"].tap()

        // The row now counts four subtasks, one of them done.
        XCTAssertTrue(app.staticTexts["1/4"].waitForExistence(timeout: 3))
    }

    func testNewTaskFromQuickAddDetails() {
        let app = XCUIApplication.demo()
        app.launch()

        app.buttons["quickAddButton"].tap()
        app.textFields["quickAddField"].typeText("Book a table")
        app.buttons["More Details"].tap()

        let title = app.textFields["titleField"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))
        XCTAssertEqual(title.value as? String, "Book a table")
        app.buttons["saveButton"].tap()

        XCTAssertTrue(app.staticTexts["Book a table"].waitForExistence(timeout: 3))
    }
}
