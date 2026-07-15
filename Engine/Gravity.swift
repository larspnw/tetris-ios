import Foundation

/// Gravity using the Tetris Worlds formula: seconds per line as a function of level.
///   secondsPerLine = (0.8 − (level − 1) × 0.007) ^ (level − 1)
public enum Gravity {
    public static func secondsPerLine(level: Int) -> Double {
        let l = Double(max(1, level) - 1)
        let base = 0.8 - l * 0.007
        return pow(base, l)
    }

    /// Cells per second at a given level (the reciprocal).
    public static func cellsPerSecond(level: Int) -> Double {
        1.0 / secondsPerLine(level: level)
    }

    // MARK: - Zen

    /// Zen keeps a fixed, relaxed pace forever (the level-1 rate of the Worlds curve).
    public static let zenSecondsPerLine: Double = 1.0

    // MARK: - Classic (NES)

    /// NES NTSC frame rate.
    public static let nesFramesPerSecond = 60.0988

    /// NES frames-per-row for levels 0–18; 19–28 take 2 frames, 29+ take 1 (the killscreen).
    private static let nesFramesPerRow = [48, 43, 38, 33, 28, 23, 18, 13, 8, 6,
                                          5, 5, 5, 4, 4, 4, 3, 3, 3]

    /// Seconds per row for a 0-based NES level.
    public static func nesSecondsPerRow(nesLevel: Int) -> Double {
        let frames: Int
        switch nesLevel {
        case ..<0:    frames = nesFramesPerRow[0]
        case 0...18:  frames = nesFramesPerRow[nesLevel]
        case 19...28: frames = 2
        default:      frames = 1
        }
        return Double(frames) / nesFramesPerSecond
    }
}
