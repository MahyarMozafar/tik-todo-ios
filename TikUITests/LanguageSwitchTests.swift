import XCTest

final class LanguageSwitchTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// English to Farsi and back again, without restarting the app. The task
    /// rows must follow along: check circles on the right in Farsi, and back
    /// on the left in English (they used to stay flipped and mirrored).
    func testSwitchingToFarsiAndBackToEnglish() {
        let app = XCUIApplication.demo(language: "en")
        app.launch()
        XCTAssertLessThan(firstCheck(in: app).frame.midX, middle(of: app))

        pickLanguage("\u{0641}\u{0627}\u{0631}\u{0633}\u{06CC}", in: app)   // "Farsi", written in Farsi
        XCTAssertGreaterThan(firstCheck(in: app).frame.midX, middle(of: app))
        Screenshot.save("language-farsi")

        pickLanguage("English", in: app)
        XCTAssertLessThan(firstCheck(in: app).frame.midX, middle(of: app))
        Screenshot.save("language-english-again")
    }

    private func firstCheck(in app: XCUIApplication) -> XCUIElement {
        let check = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'check-'")).firstMatch
        XCTAssertTrue(check.waitForExistence(timeout: 5))
        return check
    }

    private func middle(of app: XCUIApplication) -> CGFloat {
        app.windows.firstMatch.frame.midX
    }

    private func pickLanguage(_ name: String, in app: XCUIApplication) {
        app.buttons["settingsButton"].tap()
        let picker = app.buttons["languagePicker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 3))
        picker.tap()
        app.buttons[name].firstMatch.tap()

        // Settings stays open while the screens behind it change language.
        let close = app.buttons["closeSettings"]
        XCTAssertTrue(close.waitForExistence(timeout: 3))
        close.tap()
    }
}
