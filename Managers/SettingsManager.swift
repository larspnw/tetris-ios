import Foundation

/// Enum representing different drop speed options
enum DropSpeed: String, CaseIterable, Identifiable {
    case slow = "Slow"
    case normal = "Normal"
    case fast = "Fast"
    
    var id: String { rawValue }
    
    /// Display name for the speed option
    var displayName: String { rawValue }
    
    /// Base multiplier for the fall interval (lower = faster)
    var speedMultiplier: Double {
        switch self {
        case .slow: return 1.5    // 1.5x slower than normal
        case .normal: return 1.0  // Normal speed
        case .fast: return 0.6    // 0.6x faster than normal
        }
    }
    
    /// Description of the speed
    var description: String {
        switch self {
        case .slow: return "Relaxed pace"
        case .normal: return "Classic Tetris"
        case .fast: return "Quick thinking required"
        }
    }
    
    /// Icon name for the speed
    var iconName: String {
        switch self {
        case .slow: return "tortoise.fill"
        case .normal: return "figure.walk"
        case .fast: return "hare.fill"
        }
    }
}

/// Manages game settings using UserDefaults
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let dropSpeed = "tetris_dropSpeed"
    }
    
    // MARK: - Drop Speed
    
    @Published var dropSpeed: DropSpeed {
        didSet {
            defaults.set(dropSpeed.rawValue, forKey: Keys.dropSpeed)
        }
    }
    
    /// Get the base interval multiplier for the current speed setting
    var speedMultiplier: Double {
        return dropSpeed.speedMultiplier
    }
    
    // MARK: - Initialization
    
    private init() {
        if let savedSpeed = defaults.string(forKey: Keys.dropSpeed),
           let speed = DropSpeed(rawValue: savedSpeed) {
            self.dropSpeed = speed
        } else {
            self.dropSpeed = .normal
        }
    }
    
    // MARK: - Reset
    
    func resetToDefaults() {
        dropSpeed = .normal
    }
}