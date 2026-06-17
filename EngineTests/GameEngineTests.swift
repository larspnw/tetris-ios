import XCTest
@testable import TetrisEngine

final class GameEngineTests: XCTestCase {

    private func engine(_ mode: GameMode, seed: UInt64 = 1) -> GameEngine {
        GameEngine(mode: mode, previewCount: 5, rng: SeededGenerator(seed: seed))
    }

    func testStartInitializes() {
        let e = engine(.zen)
        e.start()
        XCTAssertEqual(e.status, .playing)
        XCTAssertEqual(e.score, 0)
        XCTAssertEqual(e.lines, 0)
        XCTAssertEqual(e.level, 1)
        XCTAssertEqual(e.nextQueue().count, 5)
        XCTAssertFalse(e.field.collides(e.current)) // spawned legally
    }

    func testMoveLeftRight() {
        let e = engine(.zen)
        e.start()
        let x0 = e.current.origin.x
        XCTAssertTrue(e.moveLeft())
        XCTAssertEqual(e.current.origin.x, x0 - 1)
        XCTAssertTrue(e.moveRight())
        XCTAssertEqual(e.current.origin.x, x0)
    }

    func testRotateChangesState() {
        let e = engine(.zen)
        e.start()
        XCTAssertTrue(e.rotate(clockwise: true))
        XCTAssertEqual(e.current.state, .right)
        XCTAssertTrue(e.rotate(clockwise: false))
        XCTAssertEqual(e.current.state, .spawn)
    }

    func testHardDropLocksAndScores() {
        let e = engine(.zen)
        e.start()
        let d = e.field.dropDistance(e.current)
        e.hardDrop()
        XCTAssertEqual(e.piecesPlaced, 1)
        XCTAssertEqual(e.score, 2 * d) // 2 points per cell, empty board → no line bonus
    }

    func testHoldSwapsAndIsOncePerPiece() {
        let e = engine(.zen)
        e.start()
        let first = e.current.kind
        e.hold()
        XCTAssertEqual(e.holdKind, first)
        let afterHold = e.current.kind
        e.hold() // should be a no-op until the next lock
        XCTAssertEqual(e.holdKind, first)
        XCTAssertEqual(e.current.kind, afterHold)
    }

    func testSoftDropAwardsPoints() {
        let e = engine(.zen)
        e.start()
        e.setSoftDrop(true)
        e.advance(dt: 0.2)
        XCTAssertGreaterThan(e.score, 0)
    }

    func testLockDelayLocksAfterHalfSecond() {
        let e = engine(.zen)
        e.start()
        e.setSoftDrop(true)
        e.advance(dt: 2.0) // soft-drops to the floor; now resting
        e.setSoftDrop(false)
        XCTAssertTrue(e.isOnGround)
        let placed = e.piecesPlaced
        e.advance(dt: 0.3)
        XCTAssertEqual(e.piecesPlaced, placed, "should not lock before 0.5s")
        e.advance(dt: 0.3)
        XCTAssertEqual(e.piecesPlaced, placed + 1, "should lock after 0.5s on the ground")
    }

    func testSoftDropStepMovesOneCellAndScores() {
        let e = engine(.zen)
        e.start()
        let y0 = e.current.origin.y
        XCTAssertTrue(e.softDropStep())
        XCTAssertEqual(e.current.origin.y, y0 + 1)
        XCTAssertEqual(e.score, 1)
    }

    func testLineClearAnimationFreezesThenCollapses() {
        let e = engine(.zen)
        e.start()
        e.lineClearDelay = 0.3
        // Pre-fill the bottom row so the next lock triggers a clear.
        var f = Playfield()
        let bottom = f.totalHeight - 1
        for x in 0..<f.width { f.setCell(.o, at: Coord(x, bottom)) }
        e._testLoadField(f)

        e.hardDrop() // locks on top of the full row → enters the clearing animation
        XCTAssertTrue(e.isClearing)
        XCTAssertEqual(e.clearingRows, [bottom])
        XCTAssertEqual(e.lines, 1)
        XCTAssertGreaterThan(e.clearProgress, 0.0 - 0.0001)

        // Inputs are gated while clearing.
        XCTAssertFalse(e.moveLeft())
        XCTAssertFalse(e.rotate(clockwise: true))

        e.advance(dt: 0.1)
        XCTAssertTrue(e.isClearing, "still animating before the delay elapses")

        e.advance(dt: 0.3) // past the delay → collapse + spawn
        XCTAssertFalse(e.isClearing)
        XCTAssertFalse(e.field.isRowFull(bottom))
        XCTAssertEqual(e.clearProgress, 0)
    }

    func testGravityMovesPieceDown() {
        let e = engine(.zen)
        e.start()
        let y0 = e.current.origin.y
        e.advance(dt: 1.0) // level 1 = 1s per line → exactly one step
        XCTAssertEqual(e.current.origin.y, y0 + 1)
    }

    func testPauseResumeGatesAdvance() {
        let e = engine(.zen)
        e.start()
        e.pause()
        let y0 = e.current.origin.y
        e.advance(dt: 5.0)
        XCTAssertEqual(e.current.origin.y, y0, "paused engine should not advance")
        e.resume()
        e.advance(dt: 1.0)
        XCTAssertEqual(e.current.origin.y, y0 + 1)
    }

    func testUltraFinishesAtTimeLimit() {
        let e = engine(.ultra)
        e.start()
        XCTAssertEqual(e.timeRemaining, 120)
        e.advance(dt: 130)
        XCTAssertEqual(e.status, .finished)
        XCTAssertEqual(e.elapsedTime, 120)
    }

    func testSprintReportsProgress() {
        let e = engine(.sprint)
        e.start()
        XCTAssertEqual(e.linesRemaining, 40)
        XCTAssertTrue(e.mode.ranksByTime)
    }

    func testZenNeverEnds() {
        let e = engine(.zen)
        e.start()
        for _ in 0..<300 {
            XCTAssertEqual(e.status, .playing)
            e.hardDrop()
        }
        XCTAssertEqual(e.status, .playing, "Zen resets on top-out instead of ending")
    }

    func testNonZenTopsOut() {
        let e = engine(.sprint)
        e.start()
        var i = 0
        while e.status == .playing && i < 600 { e.hardDrop(); i += 1 }
        XCTAssertEqual(e.status, .gameOver, "stacking without clears should top out")
    }
}
