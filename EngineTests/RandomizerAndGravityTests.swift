import XCTest
@testable import TetrisEngine

final class RandomizerAndGravityTests: XCTestCase {

    func testSevenBagContainsAllKindsEachCycle() {
        var bag = SevenBag(rng: SeededGenerator(seed: 42))
        for _ in 0..<5 {
            var seen: [TetrominoKind] = []
            for _ in 0..<7 { seen.append(bag.next()) }
            XCTAssertEqual(Set(seen), Set(TetrominoKind.allCases),
                           "each bag of 7 should contain all kinds exactly once")
            XCTAssertEqual(seen.count, 7)
        }
    }

    func testPreviewDoesNotConsume() {
        var bag = SevenBag(rng: SeededGenerator(seed: 7))
        let preview = bag.preview(5)
        XCTAssertEqual(preview.count, 5)
        // The next draws must match the preview, in order.
        for kind in preview {
            XCTAssertEqual(bag.next(), kind)
        }
    }

    func testSeededGeneratorIsDeterministic() {
        var a = SeededGenerator(seed: 123)
        var b = SeededGenerator(seed: 123)
        var bagA = SevenBag(rng: a)
        var bagB = SevenBag(rng: b)
        let seqA = (0..<14).map { _ in bagA.next() }
        let seqB = (0..<14).map { _ in bagB.next() }
        XCTAssertEqual(seqA, seqB)
        _ = (a, b)
    }

    func testGravityLevelOneIsOneSecond() {
        XCTAssertEqual(Gravity.secondsPerLine(level: 1), 1.0, accuracy: 1e-9)
    }

    func testGravityMatchesTetrisWorldsTable() {
        XCTAssertEqual(Gravity.secondsPerLine(level: 2), 0.793, accuracy: 0.001)
        XCTAssertEqual(Gravity.secondsPerLine(level: 5), 0.355, accuracy: 0.001)
        XCTAssertEqual(Gravity.secondsPerLine(level: 9), 0.094, accuracy: 0.001)
    }

    func testGravityIsMonotonicallyFaster() {
        for level in 1..<15 {
            XCTAssertGreaterThan(Gravity.secondsPerLine(level: level),
                                 Gravity.secondsPerLine(level: level + 1))
        }
        XCTAssertEqual(Gravity.cellsPerSecond(level: 1), 1.0, accuracy: 1e-9)
    }
}
