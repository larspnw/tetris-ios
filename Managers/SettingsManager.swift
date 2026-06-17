import Foundation
import SwiftUI

/// Control schemes for touch input (Phase 5).
enum ControlScheme: String, CaseIterable, Identifiable {
    case swipe = "Swipe"      // swipe to move/drop, tap to rotate
    case drag  = "Drag"       // cell-snapped horizontal drag, tap to rotate, swipe up to hold
    case buttons = "Buttons"  // on-screen D-pad + action buttons

    var id: String { rawValue }
    var displayName: String { rawValue }
    var detail: String {
        switch self {
        case .swipe:   return "Swipe to move, tap to rotate, swipe down to hard drop"
        case .drag:    return "Drag piece across cells, tap to rotate, flick down to drop"
        case .buttons: return "On-screen controls in the thumb zone"
        }
    }
}

/// Persisted user settings. `@Published` so SwiftUI views react and `UserDefaults`-backed
/// so they survive relaunch.
final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let hapticsEnabled = "tetris_hapticsEnabled"
        static let soundEnabled = "tetris_soundEnabled"
        static let ghostEnabled = "tetris_ghostEnabled"
        static let controlScheme = "tetris_controlScheme"
        static let dasMilliseconds = "tetris_dasMilliseconds"
        static let arrMilliseconds = "tetris_arrMilliseconds"
    }

    @Published var hapticsEnabled: Bool { didSet { defaults.set(hapticsEnabled, forKey: Keys.hapticsEnabled) } }
    @Published var soundEnabled: Bool { didSet { defaults.set(soundEnabled, forKey: Keys.soundEnabled) } }
    @Published var ghostEnabled: Bool { didSet { defaults.set(ghostEnabled, forKey: Keys.ghostEnabled) } }
    @Published var controlScheme: ControlScheme { didSet { defaults.set(controlScheme.rawValue, forKey: Keys.controlScheme) } }

    /// Delayed Auto Shift: ms held before a move repeats. Tunable for skilled play.
    @Published var dasMilliseconds: Double { didSet { defaults.set(dasMilliseconds, forKey: Keys.dasMilliseconds) } }
    /// Auto Repeat Rate: ms between repeats once DAS engages.
    @Published var arrMilliseconds: Double { didSet { defaults.set(arrMilliseconds, forKey: Keys.arrMilliseconds) } }

    private init() {
        let d = UserDefaults.standard
        func boolOrDefault(_ key: String, _ fallback: Bool) -> Bool {
            d.object(forKey: key) == nil ? fallback : d.bool(forKey: key)
        }
        hapticsEnabled = boolOrDefault(Keys.hapticsEnabled, true)
        soundEnabled = boolOrDefault(Keys.soundEnabled, true)
        ghostEnabled = boolOrDefault(Keys.ghostEnabled, true)
        controlScheme = ControlScheme(rawValue: d.string(forKey: Keys.controlScheme) ?? "") ?? .swipe
        dasMilliseconds = (d.object(forKey: Keys.dasMilliseconds) as? Double) ?? 167  // ≈ 10 frames
        arrMilliseconds = (d.object(forKey: Keys.arrMilliseconds) as? Double) ?? 33   // ≈ 2 frames
    }

    func resetToDefaults() {
        hapticsEnabled = true
        soundEnabled = true
        ghostEnabled = true
        controlScheme = .swipe
        dasMilliseconds = 167
        arrMilliseconds = 33
    }
}
