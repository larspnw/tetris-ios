import Foundation

/// Manages persistent game statistics using UserDefaults
class StatsManager {
    static let shared = StatsManager()
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let highScore = "tetris_highScore"
        static let totalTimePlayedSeconds = "tetris_totalTimePlayedSeconds"
    }
    
    // MARK: - High Score
    
    var highScore: Int {
        get { defaults.integer(forKey: Keys.highScore) }
        set { defaults.set(newValue, forKey: Keys.highScore) }
    }
    
    func updateHighScore(_ score: Int) {
        if score > highScore {
            highScore = score
        }
    }
    
    // MARK: - Total Time Played
    
    var totalTimePlayedSeconds: TimeInterval {
        get { defaults.double(forKey: Keys.totalTimePlayedSeconds) }
        set { defaults.set(newValue, forKey: Keys.totalTimePlayedSeconds) }
    }
    
    func addTimePlayed(_ seconds: TimeInterval) {
        totalTimePlayedSeconds += seconds
    }
    
    /// Format total time played in a human-readable format (e.g., "5h 23m" or "45m 12s")
    func formattedTotalTimePlayed() -> String {
        return formatTimeInterval(totalTimePlayedSeconds)
    }
    
    /// Format any time interval nicely
    func formatTimeInterval(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    // MARK: - Reset (for testing)
    
    func resetAllStats() {
        defaults.removeObject(forKey: Keys.highScore)
        defaults.removeObject(forKey: Keys.totalTimePlayedSeconds)
    }
}
