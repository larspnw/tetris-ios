import Foundation

/// The three supported game modes.
public enum GameMode: String, CaseIterable, Equatable, Sendable {
    case sprint   // clear 40 lines as fast as possible; the time is your score
    case ultra    // 120-second score attack
    case zen      // endless, no top-out

    public var title: String {
        switch self {
        case .sprint: return "Sprint"
        case .ultra:  return "Ultra"
        case .zen:    return "Zen"
        }
    }

    public var subtitle: String {
        switch self {
        case .sprint: return "Clear 40 lines, fast"
        case .ultra:  return "Most points in 2:00"
        case .zen:    return "Endless. No game over."
        }
    }

    /// Whether the leaderboard ranks by time (ascending) rather than score (descending).
    public var ranksByTime: Bool { self == .sprint }

    public static let sprintLineGoal = 40
    public static let ultraDuration: TimeInterval = 120
}
