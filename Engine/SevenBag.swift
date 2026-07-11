import Foundation

/// A source of upcoming tetrominoes. RNG is injected so gameplay is reproducible in tests.
public protocol PieceRandomizer {
    mutating func next() -> TetrominoKind
    /// Peek the upcoming `count` kinds without consuming them.
    mutating func preview(_ count: Int) -> [TetrominoKind]
}

/// 7-bag randomizer: shuffles all seven kinds, dispenses them, then refills.
/// Guarantees every kind appears once per 7 draws (≤12 between repeats).
public struct SevenBag: PieceRandomizer {
    private var queue: [TetrominoKind] = []
    private var rng: any RandomNumberGenerator

    public init(rng: any RandomNumberGenerator = SystemRandomNumberGenerator()) {
        self.rng = rng
    }

    private mutating func refillIfNeeded() {
        if queue.isEmpty {
            queue = TetrominoKind.allCases.shuffled(using: &rng)
        }
    }

    public mutating func next() -> TetrominoKind {
        refillIfNeeded()
        return queue.removeFirst()
    }

    /// Peek the upcoming `count` kinds without consuming them.
    public mutating func preview(_ count: Int) -> [TetrominoKind] {
        while queue.count < count {
            queue.append(contentsOf: TetrominoKind.allCases.shuffled(using: &rng))
        }
        return Array(queue.prefix(count))
    }
}

/// NES-style memoryless randomizer: uniform pick with a single reroll when it matches
/// the previous piece. The reroll may still repeat — droughts and floods are the point.
public struct ClassicRandomizer: PieceRandomizer {
    private var queue: [TetrominoKind] = []   // pre-drawn pieces (for preview)
    private var lastDispensed: TetrominoKind?
    private var rng: any RandomNumberGenerator

    public init(rng: any RandomNumberGenerator = SystemRandomNumberGenerator()) {
        self.rng = rng
    }

    private mutating func draw(after previous: TetrominoKind?) -> TetrominoKind {
        let first = TetrominoKind.allCases.randomElement(using: &rng)!
        guard first == previous else { return first }
        return TetrominoKind.allCases.randomElement(using: &rng)!  // one reroll, accept it
    }

    private mutating func fill(to count: Int) {
        while queue.count < count {
            queue.append(draw(after: queue.last ?? lastDispensed))
        }
    }

    public mutating func next() -> TetrominoKind {
        fill(to: 1)
        lastDispensed = queue.removeFirst()
        return lastDispensed!
    }

    public mutating func preview(_ count: Int) -> [TetrominoKind] {
        fill(to: count)
        return Array(queue.prefix(count))
    }
}

/// A small, seedable PRNG (SplitMix64) for deterministic tests and replays.
public struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    public init(seed: UInt64) { state = seed }
    public mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
