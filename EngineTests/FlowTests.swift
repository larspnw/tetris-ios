import XCTest
@testable import TetrisEngine

/// The Flow mechanic: charge by clearing lines, activate to freeze gravity and bank
/// full rows at the bottom, cash them all out (with an escalating bonus) when it ends.
final class FlowTests: XCTestCase {

    private func engine(_ mode: GameMode = .zen, seed: UInt64 = 1) -> GameEngine {
        GameEngine(mode: mode, rng: SeededGenerator(seed: seed))
    }

    /// A field whose bottom `rows` rows are already full, so the next lock banks them.
    private func fieldWithFullBottomRows(_ rows: Int = 1) -> Playfield {
        var f = Playfield()
        for r in 0..<rows {
            let y = f.totalHeight - 1 - r
            for x in 0..<f.width { f.setCell(.o, at: Coord(x, y)) }
        }
        return f
    }

    // MARK: - Charging

    func testClearingLinesChargesTheMeter() {
        let e = engine(.zen)
        e.start()
        XCTAssertEqual(e.flowCharge, 0)
        e._testLoadField(fieldWithFullBottomRows(1))
        e.hardDrop()
        XCTAssertEqual(e.flowCharge, 1.0 / Double(GameEngine.flowChargeToReady), accuracy: 1e-9)
        XCTAssertFalse(e.flowReady)
    }

    func testSprintAndClassicNeverCharge() {
        for mode in [GameMode.sprint, .classic] {
            let e = engine(mode)
            e.start()
            e._testLoadField(fieldWithFullBottomRows(1))
            e.hardDrop()
            XCTAssertEqual(e.flowCharge, 0, "\(mode) has no Flow")
            e._testFillFlowCharge()
            e.activateFlow()
            XCTAssertFalse(e.flowActive, "\(mode) cannot activate Flow")
        }
    }

    func testActivateRequiresFullMeter() {
        let e = engine(.zen)
        e.start()
        e.activateFlow()
        XCTAssertFalse(e.flowActive)
        e._testFillFlowCharge()
        XCTAssertTrue(e.flowReady)
        e.activateFlow()
        XCTAssertTrue(e.flowActive)
        XCTAssertEqual(e.flowCharge, 0, "activation spends the meter")
        XCTAssertEqual(e.flowTimeRemaining, GameEngine.flowDuration)
    }

    // MARK: - During Flow

    func testGravityIsFrozenDuringFlow() {
        let e = engine(.zen)
        e.start()
        e._testFillFlowCharge()
        e.activateFlow()
        let y0 = e.current.origin.y
        e.advance(dt: 5)   // would fall 5 rows in Zen otherwise
        XCTAssertEqual(e.current.origin.y, y0, "no gravity while Flow is active")
        XCTAssertTrue(e.flowActive)
    }

    func testFullRowsAreBankedNotCleared() {
        let e = engine(.zen)
        e.start()
        e._testFillFlowCharge()
        e.activateFlow()
        e._testLoadField(fieldWithFullBottomRows(2))
        let scoreBefore = e.score
        let linesBefore = e.lines
        e.hardDrop()
        XCTAssertEqual(e.flowLines, 2, "the two full rows are banked")
        XCTAssertEqual(e.lines, linesBefore, "banked lines don't count until cash-out")
        XCTAssertEqual(e.field.fullRows().count, 2, "banked rows stay on the field, at the bottom")
        XCTAssertTrue(e.field.isRowFull(e.field.totalHeight - 1))
        XCTAssertTrue(e.field.isRowFull(e.field.totalHeight - 2))
        // Only drop points so far — no clear points during Flow.
        XCTAssertGreaterThanOrEqual(e.score, scoreBefore)
        XCTAssertTrue(e.flowActive)
    }

    // MARK: - Cash-out

    func testFlowEndsAfterDurationAndCashesOut() {
        let e = engine(.zen)
        e.start()
        e._testFillFlowCharge()
        e.activateFlow()
        e._testLoadField(fieldWithFullBottomRows(3))
        e.hardDrop() // banks 3 rows
        XCTAssertEqual(e.flowLines, 3)
        let scoreBefore = e.score
        let linesBefore = e.lines
        e.advance(dt: GameEngine.flowDuration + 0.1)
        XCTAssertFalse(e.flowActive)
        XCTAssertEqual(e.flowEndCount, 1)
        XCTAssertEqual(e.lines, linesBefore + 3)
        XCTAssertEqual(e.lastFlowBonus, Scorer.flowBonus(lines: 3, level: 1))
        XCTAssertEqual(e.score, scoreBefore + e.lastFlowBonus)
        XCTAssertTrue(e.field.fullRows().isEmpty, "banked rows are cleared on cash-out")
    }

    func testUltraBuzzerCashesOutBeforeFinishing() {
        let e = engine(.ultra)
        e.start()
        e.advance(dt: GameMode.ultraDuration - 1) // nearly out of time
        e._testFillFlowCharge()
        e.activateFlow()
        e._testLoadField(fieldWithFullBottomRows(2))
        e.hardDrop() // banks 2 rows
        let scoreBefore = e.score
        e.advance(dt: 2) // past the buzzer
        XCTAssertEqual(e.status, .finished)
        XCTAssertEqual(e.score, scoreBefore + Scorer.flowBonus(lines: 2, level: 1),
                       "banked lines pay out at the buzzer")
    }

    func testBlockedSpawnCashesOutEarlyInsteadOfToppingOut() {
        let e = engine(.ultra) // a mode that CAN top out
        e.start()
        e._testFillFlowCharge()
        e.activateFlow()
        // Stack filled to the very top except one full bottom row banked-to-be;
        // leave the spawn rows occupied so the next spawn collides.
        var f = fieldWithFullBottomRows(4)
        for y in 0..<(f.bufferHeight + 2) {
            for x in 0..<f.width where x % 2 == 0 { f.setCell(.i, at: Coord(x, y)) }
        }
        e._testLoadField(f)
        e.hardDrop()
        XCTAssertFalse(e.flowActive, "flow cashed out early to make room")
        XCTAssertEqual(e.flowEndCount, 1)
        XCTAssertGreaterThan(e.score, 0)
    }

    func testFlowScoreEscalation() {
        XCTAssertEqual(Scorer.flowBonus(lines: 0, level: 1), 0)
        XCTAssertEqual(Scorer.flowBonus(lines: 1, level: 1), 100)
        XCTAssertEqual(Scorer.flowBonus(lines: 4, level: 1), 1000)
        XCTAssertEqual(Scorer.flowBonus(lines: 8, level: 1), 3600)
        XCTAssertEqual(Scorer.flowBonus(lines: 16, level: 1), 13600)
        XCTAssertEqual(Scorer.flowBonus(lines: 4, level: 3), 3000)
    }

    func testRestartResetsFlowState() {
        let e = engine(.zen)
        e.start()
        e._testFillFlowCharge()
        e.activateFlow()
        e.start()
        XCTAssertFalse(e.flowActive)
        XCTAssertEqual(e.flowCharge, 0)
        XCTAssertEqual(e.flowLines, 0)
        XCTAssertEqual(e.flowEndCount, 0)
    }

    // MARK: - Regression: soft drop still works during Flow

    func testSoftDropLowersPieceDuringFlow() {
        let e = engine(.zen)
        e.start()
        e._testFillFlowCharge()
        e.activateFlow()
        let y0 = e.current.origin.y
        e.setSoftDrop(true)
        e.advance(dt: 0.5)          // gravity is frozen, but soft drop should still descend
        XCTAssertGreaterThan(e.current.origin.y, y0, "held soft drop lowers the piece during Flow")
        XCTAssertGreaterThan(e.score, 0, "soft-drop points still accrue during Flow")
        XCTAssertTrue(e.flowActive)
    }

    func testAutomaticGravityStillFrozenWithoutSoftDrop() {
        let e = engine(.zen)
        e.start()
        e._testFillFlowCharge()
        e.activateFlow()
        let y0 = e.current.origin.y
        e.advance(dt: 5)            // no soft drop → no descent
        XCTAssertEqual(e.current.origin.y, y0)
    }

    // MARK: - Regression: hold() during Flow is bank-safe

    /// Occupy the spawn box in `f` so the next spawn collides (keeps existing cells).
    private func blockingSpawn(_ f: Playfield) -> Playfield {
        var f = f
        for y in 0..<(f.bufferHeight + 2) {
            for x in 0..<f.width where !f.isOccupied(Coord(x, y)) { f.setCell(.i, at: Coord(x, y)) }
        }
        return f
    }

    func testHoldDuringFlowCashesOutInsteadOfToppingOut() {
        let e = engine(.ultra)      // a mode that CAN top out
        e.start()
        e._testFillFlowCharge()
        e.activateFlow()
        // Bank 2 rows first.
        e._testLoadField(fieldWithFullBottomRows(2))
        e.hardDrop()
        XCTAssertEqual(e.flowLines, 2)
        // Now block the spawn and press hold → must cash out, not game over.
        e._testLoadField(blockingSpawn(e.field))
        let scoreBefore = e.score
        e.hold()
        XCTAssertNotEqual(e.status, .gameOver, "hold during Flow cashes out rather than topping out")
        XCTAssertFalse(e.flowActive)
        XCTAssertEqual(e.score, scoreBefore + Scorer.flowBonus(lines: 2, level: 1))
    }

    func testHoldDuringFlowInZenNeverCreditsVanishedRows() {
        let e = engine(.zen)
        e.start()
        e._testFillFlowCharge()
        e.activateFlow()
        // Bank 3 real rows via a normal Flow lock.
        e._testLoadField(fieldWithFullBottomRows(3))
        e.hardDrop()
        XCTAssertEqual(e.flowLines, 3)
        // Block the spawn, keeping the 3 banked rows, then hold.
        e._testLoadField(blockingSpawn(e.field))
        e.hold()
        // Cash-out happened; flow state is clean and lines were credited exactly once.
        XCTAssertFalse(e.flowActive)
        XCTAssertEqual(e.flowLines, 0)
        XCTAssertEqual(e.lines, 3, "the 3 real banked rows counted once — no phantom credit")
        // Let any remaining time pass; no second cash-out should fire.
        let linesAfterHold = e.lines
        e.advance(dt: GameEngine.flowDuration + 1)
        XCTAssertEqual(e.lines, linesAfterHold, "no phantom lines after the hold cash-out")
    }

    // MARK: - Regression: meter fills exactly (no float drift)

    func testMeterReadyAfterExactlyTwelveLinesAsSixDoubles() {
        let e = engine(.zen)
        e.start()
        for _ in 0..<6 {
            e._testLoadField(fieldWithFullBottomRows(2)) // clears 2 lines per lock
            e.hardDrop()
        }
        XCTAssertEqual(e.flowCharge, 1.0, accuracy: 0)
        XCTAssertTrue(e.flowReady, "12 lines as six doubles fills the meter exactly")
    }

    // MARK: - Regression: activateFlow reports success

    func testActivateFlowReturnsFalseWhileClearing() {
        let e = engine(.zen)
        e.start()
        e.lineClearDelay = 0.35
        e._testFillFlowCharge()
        e._testLoadField(fieldWithFullBottomRows(1))
        e.hardDrop() // enters the line-clear animation (isClearing == true)
        XCTAssertTrue(e.isClearing)
        XCTAssertFalse(e.activateFlow(), "cannot activate mid clear; returns false so the app skips juice")
        XCTAssertFalse(e.flowActive)
    }

    func testActivateFlowReturnsTrueOnSuccess() {
        let e = engine(.zen)
        e.start()
        e._testFillFlowCharge()
        XCTAssertTrue(e.activateFlow())
        XCTAssertTrue(e.flowActive)
        XCTAssertFalse(e.activateFlow(), "already active → false")
    }

    // MARK: - Playfield.sinkRows

    func testSinkRowsMovesRowsToBottomPreservingContents() {
        var f = Playfield()
        let top = f.bufferHeight // first visible row
        for x in 0..<f.width { f.setCell(.t, at: Coord(x, top)) }        // full row of T
        f.setCell(.i, at: Coord(0, top + 1))                              // stray cell below it
        f.sinkRows([top])
        let bottom = f.totalHeight - 1
        XCTAssertTrue(f.isRowFull(bottom))
        XCTAssertEqual(f.cells[bottom][0], .t, "sunk row keeps its piece kinds")
        XCTAssertEqual(f.cells[top][0], .i, "rows below the extraction shift up one index")
        XCTAssertNil(f.cells[top + 1][0])
        XCTAssertEqual(f.filledCount, f.width + 1)
    }
}
