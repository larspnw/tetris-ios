import SwiftUI

/// Maps engine piece kinds to their Guideline colors. Lives in the app layer so the
/// engine stays free of SwiftUI.
extension TetrominoKind {
    var color: Color {
        switch self {
        case .i: return Color(red: 0.0,  green: 0.78, blue: 0.92) // cyan
        case .o: return Color(red: 0.95, green: 0.78, blue: 0.05) // yellow
        case .t: return Color(red: 0.62, green: 0.20, blue: 0.78) // purple
        case .s: return Color(red: 0.20, green: 0.74, blue: 0.30) // green
        case .z: return Color(red: 0.90, green: 0.22, blue: 0.27) // red
        case .j: return Color(red: 0.18, green: 0.38, blue: 0.88) // blue
        case .l: return Color(red: 0.95, green: 0.52, blue: 0.10) // orange
        }
    }
}
