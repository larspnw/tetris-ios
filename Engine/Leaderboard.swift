import Foundation

/// One recorded run. `date` is when it finished. For Sprint the ranking metric is
/// `timeSeconds` (lower is better); for Ultra/Zen it is `score` (higher is better).
public struct LeaderboardEntry: Codable, Equatable, Sendable {
    public let mode: String          // GameMode.rawValue
    public let score: Int
    public let lines: Int
    public let timeSeconds: Double
    public let date: Date

    public init(mode: GameMode, score: Int, lines: Int, timeSeconds: Double, date: Date) {
        self.mode = mode.rawValue
        self.score = score
        self.lines = lines
        self.timeSeconds = timeSeconds
        self.date = date
    }
}

/// Abstraction over where entries live, so the core logic is testable without UserDefaults.
public protocol LeaderboardPersistence: AnyObject {
    func loadEntries() -> [LeaderboardEntry]
    func saveEntries(_ entries: [LeaderboardEntry])
}

/// Ranks and persists leaderboard entries, capped per mode.
public final class Leaderboard {
    public static let maxPerMode = 25
    private let store: LeaderboardPersistence
    private var entries: [LeaderboardEntry]

    public init(store: LeaderboardPersistence) {
        self.store = store
        self.entries = store.loadEntries()
    }

    /// Record a finished run and persist. Returns the entry's rank (1-based) within its mode.
    @discardableResult
    public func record(_ entry: LeaderboardEntry) -> Int {
        entries.append(entry)
        // Cap each mode to the best `maxPerMode`.
        for mode in GameMode.allCases {
            let ranked = sorted(mode: mode)
            if ranked.count > Self.maxPerMode {
                let keep = Set(ranked.prefix(Self.maxPerMode).map { Self.identity($0) })
                entries.removeAll { $0.mode == mode.rawValue && !keep.contains(Self.identity($0)) }
            }
        }
        store.saveEntries(entries)
        let ranked = sorted(mode: GameMode(rawValue: entry.mode) ?? .zen)
        return (ranked.firstIndex { Self.identity($0) == Self.identity(entry) } ?? 0) + 1
    }

    /// Entries for a mode, best-first.
    public func sorted(mode: GameMode) -> [LeaderboardEntry] {
        let forMode = entries.filter { $0.mode == mode.rawValue }
        if mode.ranksByTime {
            return forMode.sorted { ($0.timeSeconds, -$0.score) < ($1.timeSeconds, -$1.score) }
        } else {
            return forMode.sorted { ($0.score, -$0.timeSeconds) > ($1.score, -$1.timeSeconds) }
        }
    }

    public func best(mode: GameMode) -> LeaderboardEntry? { sorted(mode: mode).first }

    public func clear() {
        entries.removeAll()
        store.saveEntries(entries)
    }

    private static func identity(_ e: LeaderboardEntry) -> String {
        "\(e.mode)|\(e.score)|\(e.lines)|\(e.timeSeconds)|\(e.date.timeIntervalSince1970)"
    }
}
