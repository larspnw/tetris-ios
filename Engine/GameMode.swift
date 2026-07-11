import Foundation

/// The supported game modes.
public enum GameMode: String, CaseIterable, Equatable, Sendable {
    case marathon // clear 150 lines with rising speed; score is what counts
    case sprint   // clear 40 lines as fast as possible; the time is your score
    case ultra    // 120-second score attack
    case zen      // endless, no top-out, relaxed constant gravity
    case classic  // NES-style: no hold/ghost, memoryless randomizer, NES gravity & scoring

    public var title: String {
        switch self {
        case .marathon: return "Marathon"
        case .sprint:   return "Sprint"
        case .ultra:    return "Ultra"
        case .zen:      return "Zen"
        case .classic:  return "Classic"
        }
    }

    public var subtitle: String {
        switch self {
        case .marathon: return "150 lines, rising speed"
        case .sprint:   return "Clear 40 lines, fast"
        case .ultra:    return "Most points in 2:00"
        case .zen:      return "Endless. No game over."
        case .classic:  return "NES rules. No hold, no mercy."
        }
    }

    /// Whether the leaderboard ranks by time (ascending) rather than score (descending).
    public var ranksByTime: Bool { self == .sprint }

    public static let sprintLineGoal = 40
    public static let marathonLineGoal = 150
    public static let ultraDuration: TimeInterval = 120

    /// Line count that finishes the run, if the mode has one.
    public var lineGoal: Int? {
        switch self {
        case .sprint:   return Self.sprintLineGoal
        case .marathon: return Self.marathonLineGoal
        default:        return nil
        }
    }

    /// Countdown length, if the mode is time-limited.
    public var duration: TimeInterval? { self == .ultra ? Self.ultraDuration : nil }

    // Classic drops the modern conveniences; everything else plays Guideline rules.
    public var holdEnabled: Bool { self != .classic }
    public var ghostEnabled: Bool { self != .classic }
    public var usesSevenBag: Bool { self != .classic }
    public var defaultPreviewCount: Int { self == .classic ? 1 : 5 }

    /// Guideline scoring (T-spins, B2B, combo, perfect clear) vs the NES table.
    public var scoringStyle: ScoringStyle { self == .classic ? .nes : .guideline }

    /// Whether the Flow meter (freeze gravity, bank clears) is available.
    /// Sprint stays a pure race; Classic predates such luxuries.
    public var flowEnabled: Bool {
        switch self {
        case .marathon, .ultra, .zen: return true
        case .sprint, .classic:       return false
        }
    }
}
