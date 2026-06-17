import XCTest
@testable import TetrisEngine

final class ScoringTests: XCTestCase {

    func testBaseLineScores() {
        var s = Scorer()
        XCTAssertEqual(s.register(lines: 1, tspin: .none, level: 1, perfectClear: false).points, 100)
        s = Scorer()
        XCTAssertEqual(s.register(lines: 2, tspin: .none, level: 1, perfectClear: false).points, 300)
        s = Scorer()
        XCTAssertEqual(s.register(lines: 3, tspin: .none, level: 1, perfectClear: false).points, 500)
        s = Scorer()
        XCTAssertEqual(s.register(lines: 4, tspin: .none, level: 1, perfectClear: false).points, 800)
    }

    func testScoreScalesWithLevel() {
        var s = Scorer()
        XCTAssertEqual(s.register(lines: 4, tspin: .none, level: 5, perfectClear: false).points, 4000)
    }

    func testTSpinScores() {
        var s = Scorer()
        XCTAssertEqual(s.register(lines: 0, tspin: .full, level: 1, perfectClear: false).points, 400)
        s = Scorer()
        XCTAssertEqual(s.register(lines: 1, tspin: .full, level: 1, perfectClear: false).points, 800)
        s = Scorer()
        XCTAssertEqual(s.register(lines: 2, tspin: .full, level: 1, perfectClear: false).points, 1200)
        s = Scorer()
        XCTAssertEqual(s.register(lines: 3, tspin: .full, level: 1, perfectClear: false).points, 1600)
        s = Scorer()
        XCTAssertEqual(s.register(lines: 0, tspin: .mini, level: 1, perfectClear: false).points, 100)
        s = Scorer()
        XCTAssertEqual(s.register(lines: 1, tspin: .mini, level: 1, perfectClear: false).points, 200)
    }

    func testBackToBackTetrisBonus() {
        var s = Scorer()
        let first = s.register(lines: 4, tspin: .none, level: 1, perfectClear: false)
        XCTAssertEqual(first.points, 800)
        XCTAssertFalse(first.backToBack) // first difficult clear: no bonus yet
        let second = s.register(lines: 4, tspin: .none, level: 1, perfectClear: false)
        // 800 * 1.5 = 1200, plus combo bonus (combo now 1 → +50).
        XCTAssertTrue(second.backToBack)
        XCTAssertEqual(second.points, 1200 + 50)
    }

    func testNonDifficultClearBreaksBackToBack() {
        var s = Scorer()
        _ = s.register(lines: 4, tspin: .none, level: 1, perfectClear: false) // b2b armed
        _ = s.register(lines: 1, tspin: .none, level: 1, perfectClear: false) // breaks it
        let tetris = s.register(lines: 4, tspin: .none, level: 1, perfectClear: false)
        XCTAssertFalse(tetris.backToBack, "chain was broken; no bonus")
    }

    func testComboProgression() {
        var s = Scorer()
        let c1 = s.register(lines: 1, tspin: .none, level: 1, perfectClear: false)
        XCTAssertEqual(c1.combo, 0)
        XCTAssertEqual(c1.points, 100) // no combo bonus on first clear
        let c2 = s.register(lines: 1, tspin: .none, level: 1, perfectClear: false)
        XCTAssertEqual(c2.combo, 1)
        XCTAssertEqual(c2.points, 100 + 50) // +50 * combo(1) * level(1)
        let broken = s.register(lines: 0, tspin: .none, level: 1, perfectClear: false)
        XCTAssertEqual(broken.combo, -1)
    }

    func testPerfectClearBonus() {
        var s = Scorer()
        let out = s.register(lines: 1, tspin: .none, level: 1, perfectClear: true)
        XCTAssertTrue(out.perfectClear)
        XCTAssertEqual(out.points, 100 + 800) // single + single-PC bonus
    }

    func testTSpinNoLineDoesNotBreakBackToBack() {
        var s = Scorer()
        _ = s.register(lines: 4, tspin: .none, level: 1, perfectClear: false) // b2b armed
        _ = s.register(lines: 0, tspin: .full, level: 1, perfectClear: false) // no line, keeps chain
        let tetris = s.register(lines: 4, tspin: .none, level: 1, perfectClear: false)
        XCTAssertTrue(tetris.backToBack, "T-spin with no line clear should not break B2B")
    }
}
