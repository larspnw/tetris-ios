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
}
