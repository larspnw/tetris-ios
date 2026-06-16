import Foundation

/// 7-bag randomizer: shuffles all seven kinds, dispenses them, then refills.
/// Guarantees every kind appears once per 7 draws (≤12 between repeats).
/// RNG is injected so gameplay is reproducible in tests.
public struct SevenBag {
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
