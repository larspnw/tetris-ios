import Foundation

/// Which scoring rules a mode uses.
public enum ScoringStyle: Equatable, Sendable {
    case guideline  // T-spins, back-to-back, combo, perfect clear
    case nes        // the 1989 table: 40/100/300/1200 × level, nothing else
}

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

    /// NES scoring: 40/100/300/1200 for 1–4 lines, multiplied by the (1-based) level.
    /// (The engine's 1-based level equals the NES 0-based level + 1, which is exactly
    /// the NES multiplier.) No T-spins, B2B, combos, or perfect clears in 1989.
    public static func nesPoints(lines: Int, level: Int) -> Int {
        let base: Int
        switch lines {
        case 1: base = 40
        case 2: base = 100
        case 3: base = 300
        case 4: base = 1200
        default: base = 0
        }
        return base * max(1, level)
    }
}
