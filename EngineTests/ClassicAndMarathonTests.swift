import XCTest
@testable import TetrisEngine

/// Rules specific to the Marathon, Classic (NES), and Zen modes.
final class ClassicAndMarathonTests: EngineTestCase {

    // MARK: - Marathon

    func testMarathonReportsProgressAndRanksByScore() {
        let e = engine(.marathon)
        e.start()
        XCTAssertEqual(e.linesRemaining, 150)
        XCTAssertNil(e.timeRemaining)
        XCTAssertFalse(e.mode.ranksByTime)
    }

    func testMarathonFinishesAtLineGoal() {
        let e = engine(.marathon)
        e.start()
        // Cheat the count up to the brink, then clear one real line.
        e._testSetLines(GameMode.marathonLineGoal - 1)
        e._testLoadField(fieldWithFullBottomRows())
        e.hardDrop() // locks; the pre-filled full row clears → goal reached
        XCTAssertEqual(e.status, .finished)
        XCTAssertGreaterThanOrEqual(e.lines, GameMode.marathonLineGoal)
        XCTAssertTrue(e.field.fullRows().isEmpty, "goal rows are removed on finish")
    }

    // MARK: - Zen

    func testZenGravityIsConstantAndRelaxed() {
        let e = engine(.zen)
        e.start()
        e._testSetLines(200) // level 21 — would be blisteringly fast on the Worlds curve
        let y0 = e.current.origin.y
        e.advance(dt: Gravity.zenSecondsPerLine)
        XCTAssertEqual(e.current.origin.y, y0 + 1, "Zen falls exactly one row per zen interval")
        let y1 = e.current.origin.y
        e.advance(dt: Gravity.zenSecondsPerLine / 2)
        XCTAssertEqual(e.current.origin.y, y1, "no faster than the fixed zen pace")
    }

    // MARK: - Classic (NES)

    func testNesGravityTable() {
        let fps = Gravity.nesFramesPerSecond
        XCTAssertEqual(Gravity.nesSecondsPerRow(nesLevel: 0), 48 / fps, accuracy: 1e-9)
        XCTAssertEqual(Gravity.nesSecondsPerRow(nesLevel: 8), 8 / fps, accuracy: 1e-9)
        XCTAssertEqual(Gravity.nesSecondsPerRow(nesLevel: 9), 6 / fps, accuracy: 1e-9)
        XCTAssertEqual(Gravity.nesSecondsPerRow(nesLevel: 18), 3 / fps, accuracy: 1e-9)
        XCTAssertEqual(Gravity.nesSecondsPerRow(nesLevel: 19), 2 / fps, accuracy: 1e-9)
        XCTAssertEqual(Gravity.nesSecondsPerRow(nesLevel: 28), 2 / fps, accuracy: 1e-9)
        XCTAssertEqual(Gravity.nesSecondsPerRow(nesLevel: 29), 1 / fps, accuracy: 1e-9, "the killscreen")
        XCTAssertEqual(Gravity.nesSecondsPerRow(nesLevel: 155), 1 / fps, accuracy: 1e-9)
    }

    func testNesScoringTable() {
        XCTAssertEqual(Scorer.nesPoints(lines: 1, level: 1), 40)
        XCTAssertEqual(Scorer.nesPoints(lines: 2, level: 1), 100)
        XCTAssertEqual(Scorer.nesPoints(lines: 3, level: 1), 300)
        XCTAssertEqual(Scorer.nesPoints(lines: 4, level: 1), 1200)
        XCTAssertEqual(Scorer.nesPoints(lines: 4, level: 10), 12000)
        XCTAssertEqual(Scorer.nesPoints(lines: 0, level: 5), 0)
    }

    func testClassicHoldIsDisabled() {
        let e = engine(.classic)
        e.start()
        let kind = e.current.kind
        e.hold()
        XCTAssertNil(e.holdKind, "Classic has no hold")
        XCTAssertEqual(e.current.kind, kind)
    }

    func testClassicPreviewShowsOnePiece() {
        let e = engine(.classic)
        e.start()
        XCTAssertEqual(e.previewCount, 1)
        XCTAssertEqual(e.nextQueue().count, 1)
    }

    func testClassicUsesNesScoringWithoutGuidelineBonuses() {
        let e = engine(.classic)
        e.start()
        e._testLoadField(fieldWithFullBottomRows())
        let dropPoints = 2 * e.field.dropDistance(e.current)
        e.hardDrop()
        XCTAssertEqual(e.lines, 1)
        XCTAssertEqual(e.score, dropPoints + 40, "single = 40 × level 1, no combo/B2B")
        XCTAssertEqual(e.lastOutcome.tspin, .none)
    }

    func testClassicLocksWithoutModernLockDelay() {
        let e = engine(.classic)
        e.start()
        e.setSoftDrop(true)
        e.advance(dt: 2.0) // reaches the floor
        e.setSoftDrop(false)
        XCTAssertTrue(e.isOnGround)
        let placed = e.piecesPlaced
        // One NES gravity step at level 1 (nesLevel 0) is 43/60.0988 ≈ 0.716s;
        // the piece must lock within that window — long before the modern 0.5s + resets.
        e.advance(dt: Gravity.nesSecondsPerRow(nesLevel: 0) + 0.01)
        XCTAssertEqual(e.piecesPlaced, placed + 1, "grounded classic piece locks after one gravity step")
    }

    func testClassicRandomizerIsMemorylessWithSingleReroll() {
        var rng = SeededGenerator(seed: 42)
        var r = ClassicRandomizer(rng: rng)
        // Deterministic with the same seed.
        rng = SeededGenerator(seed: 42)
        var r2 = ClassicRandomizer(rng: rng)
        let a = (0..<50).map { _ in r.next() }
        let b = (0..<50).map { _ in r2.next() }
        XCTAssertEqual(a, b, "seeded draws are reproducible")

        // Preview matches what next() dispenses.
        var r3 = ClassicRandomizer(rng: SeededGenerator(seed: 7))
        let peek = r3.preview(3)
        XCTAssertEqual([r3.next(), r3.next(), r3.next()], peek)

        // All 7 kinds appear over a long run, and immediate repeats are rare but
        // possible (the reroll can match) — NES behavior, unlike the 7-bag.
        var r4 = ClassicRandomizer(rng: SeededGenerator(seed: 99))
        let run = (0..<2000).map { _ in r4.next() }
        XCTAssertEqual(Set(run), Set(TetrominoKind.allCases))
        let repeats = zip(run, run.dropFirst()).filter { $0 == $1 }.count
        // Expected repeat rate ≈ 1/49 ≈ 2%; assert it's in a sane band (0.2%–8%).
        XCTAssertGreaterThan(repeats, 3)
        XCTAssertLessThan(repeats, 160)
    }
}
