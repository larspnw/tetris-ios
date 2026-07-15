import XCTest
@testable import TetrisEngine

/// Shared fixtures for engine tests: a seeded (deterministic) engine and common board
/// setups, so the same helpers aren't re-implemented in each test file.
class EngineTestCase: XCTestCase {

    /// A deterministic engine for `mode`, seeded so runs are reproducible.
    func engine(_ mode: GameMode, seed: UInt64 = 1) -> GameEngine {
        GameEngine(mode: mode, rng: SeededGenerator(seed: seed))
    }

    /// A field whose bottom `rows` rows are already full, so the next lock clears (or,
    /// during Flow, banks) them.
    func fieldWithFullBottomRows(_ rows: Int = 1) -> Playfield {
        var f = Playfield()
        for r in 0..<rows {
            let y = f.totalHeight - 1 - r
            for x in 0..<f.width { f.setCell(.o, at: Coord(x, y)) }
        }
        return f
    }
}
