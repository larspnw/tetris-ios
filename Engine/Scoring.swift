import Foundation

/// Outcome of locking a piece, used to drive scoring and UI feedback.
public struct ClearOutcome: Equatable, Sendable {
    public var linesCleared: Int
    public var tspin: TSpin
    public var perfectClear: Bool
    public var backToBack: Bool   // did this clear extend a B2B chain (got the bonus)?
    public var combo: Int         // combo count after this clear (-1 = no active combo)
    public var points: Int        // points awarded for this clear (excl. drop points)

    public static let zero = ClearOutcome(linesCleared: 0, tspin: .none, perfectClear: false,
                                          backToBack: false, combo: -1, points: 0)
}

/// Stateful Guideline scorer: tracks back-to-back and combo across placements.
public struct Scorer: Sendable {
    public private(set) var backToBackActive = false
    public private(set) var combo = -1   // starts at -1; first clear makes it 0

    public init() {}

    /// True for "difficult" clears that build/extend a back-to-back chain.
    private static func isDifficult(lines: Int, tspin: TSpin) -> Bool {
        if lines == 0 { return false }
        if tspin != .none { return true }       // any T-spin line clear
        return lines == 4                        // a Tetris
    }

    /// Base action points (× level applied by caller) before the B2B multiplier.
    private static func actionPoints(lines: Int, tspin: TSpin) -> Int {
        switch tspin {
        case .full:
            switch lines {
            case 0: return 400
            case 1: return 800
            case 2: return 1200
            case 3: return 1600
            default: return 0
            }
        case .mini:
            switch lines {
            case 0: return 100
            case 1: return 200
            default: return 200
            }
        case .none:
            switch lines {
            case 1: return 100
            case 2: return 300
            case 3: return 500
            case 4: return 800
            default: return 0
            }
        }
    }

    private static func perfectClearBonus(lines: Int, b2bTetris: Bool) -> Int {
        switch lines {
        case 1: return 800
        case 2: return 1200
        case 3: return 1800
        case 4: return b2bTetris ? 3200 : 2000
        default: return 0
        }
    }

    /// Register a locked piece's result, mutating B2B/combo state, returning the outcome.
    public mutating func register(lines: Int, tspin: TSpin, level: Int, perfectClear: Bool) -> ClearOutcome {
        let lvl = max(1, level)
        let difficult = Self.isDifficult(lines: lines, tspin: tspin)

        // Combo: only line clears participate.
        if lines > 0 { combo += 1 } else { combo = -1 }

        var points = Self.actionPoints(lines: lines, tspin: tspin) * lvl

        // Back-to-back: apply ×1.5 to the action points if the chain was already active.
        var gotB2BBonus = false
        if difficult {
            if backToBackActive {
                points = points + points / 2   // ×1.5
                gotB2BBonus = true
            }
            backToBackActive = true
        } else if lines > 0 {
            backToBackActive = false           // a non-difficult line clear breaks the chain
        }
        // (a no-line placement leaves the chain intact)

        // Combo bonus.
        if lines > 0 && combo > 0 {
            points += 50 * combo * lvl
        }

        // Perfect clear bonus.
        if perfectClear && lines > 0 {
            points += Self.perfectClearBonus(lines: lines, b2bTetris: gotB2BBonus && lines == 4) * lvl
        }

        return ClearOutcome(linesCleared: lines, tspin: tspin, perfectClear: perfectClear && lines > 0,
                            backToBack: gotB2BBonus, combo: combo, points: points)
    }

    public mutating func reset() {
        backToBackActive = false
        combo = -1
    }
}
