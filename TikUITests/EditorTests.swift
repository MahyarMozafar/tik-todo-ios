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

final class RepeatTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testTickingARepeatingTaskAddsTheNextOne() {
        let app = XCUIApplication.demo()
        app.launch()

        // "Read 20 pages" repeats every day. Ticking it adds tomorrow's copy.
        app.buttons["check-Read 20 pages"].tap()

        app.tabBars.buttons["Lists"].tap()
        app.buttons["smart-scheduled"].tap()
        XCTAssertTrue(app.staticTexts["Read 20 pages"].waitForExistence(timeout: 3))
    }

    func testPickingCertainWeekdays() {
        let app = XCUIApplication.demo()
        app.launch()

        app.staticTexts["Call mom"].tap()
        XCTAssertTrue(app.textFields["titleField"].waitForExistence(timeout: 3))
        let repeatRow = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Repeat'")).firstMatch
        for _ in 0..<4 where !repeatRow.isHittable {
            app.swipeUp()
        }
        repeatRow.tap()
        app.buttons["On Certain Days"].tap()
        Screenshot.save("repeat")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["saveButton"].tap()

        XCTAssertTrue(app.staticTexts["Call mom"].waitForExistence(timeout: 3))
    }
}
