import XCTest

/// End-to-end UI flows. These require a booted iOS Simulator to run:
///   xcodebuild test -scheme Tetris -destination 'platform=iOS Simulator,name=iPhone 16'
final class TetrisUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        return app
    }

    /// Launch → the menu shows the title, a quote, and the Play button.
    func testLaunchShowsMenuWithQuoteAndPlay() {
        let app = launch()
        XCTAssertTrue(app.staticTexts["TETRIS"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Play"].exists)
        XCTAssertTrue(app.buttons["Leaderboard"].exists)
        // A quote attribution line (starts with "—") should be present.
        let dashQuote = app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH '—'")).firstMatch
        XCTAssertTrue(dashQuote.exists)
    }

    /// Play → choose Sprint → the game HUD appears.
    func testStartSprintGame() {
        let app = launch()
        app.buttons["Play"].tap()
        XCTAssertTrue(app.staticTexts["Choose a Mode"].waitForExistence(timeout: 5))
        app.staticTexts["Sprint"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["SCORE"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["SPRINT"].exists)
    }

    /// In a game, pause then resume.
    func testPauseAndResume() {
        let app = launch()
        app.buttons["Play"].tap()
        _ = app.staticTexts["Choose a Mode"].waitForExistence(timeout: 5)
        app.staticTexts["Zen"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["SCORE"].waitForExistence(timeout: 5))
        app.buttons["pause.circle.fill"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["PAUSED"].waitForExistence(timeout: 3))
        app.buttons["Resume"].tap()
        XCTAssertFalse(app.staticTexts["PAUSED"].exists)
    }

    /// The leaderboard opens and shows its mode tabs.
    func testLeaderboardOpens() {
        let app = launch()
        app.buttons["Leaderboard"].tap()
        XCTAssertTrue(app.staticTexts["Sprint"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Ultra"].exists)
        XCTAssertTrue(app.staticTexts["Zen"].exists)
    }
}
