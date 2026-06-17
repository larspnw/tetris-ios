import Foundation

/// UserDefaults-backed persistence for the engine's `Leaderboard`. Stored as JSON so the
/// schema can evolve without bespoke key management.
final class UserDefaultsLeaderboardStore: LeaderboardPersistence {
    private let defaults = UserDefaults.standard
    private let key = "tetris_leaderboard_v1"

    func loadEntries() -> [LeaderboardEntry] {
        guard let data = defaults.data(forKey: key),
              let entries = try? JSONDecoder().decode([LeaderboardEntry].self, from: data) else {
            return []
        }
        return entries
    }

    func saveEntries(_ entries: [LeaderboardEntry]) {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: key)
        }
    }
}

/// Shared app-wide leaderboard instance.
enum LeaderboardService {
    static let shared = Leaderboard(store: UserDefaultsLeaderboardStore())
}
