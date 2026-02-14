import SwiftUI

/// Represents the seven standard Tetris pieces (tetrominoes)
enum TetrominoType: CaseIterable {
    case i, o, t, s, z, j, l
    
    /// The color associated with each piece type
    var color: Color {
        switch self {
        case .i: return .cyan
        case .o: return .yellow
        case .t: return .purple
        case .s: return .green
        case .z: return .red
        case .j: return .blue
        case .l: return .orange
        }
    }
    
    /// The starting grid position for each piece (centered at top)
    var startPosition: (x: Int, y: Int) {
        return (x: 3, y: 0)
    }
    
    /// Returns the block pattern for this piece type
    /// Each piece is defined as a 4x4 grid of booleans
    func blocks(for rotation: Int) -> [[Bool]] {
        // Normalize rotation to 0-3
        let r = ((rotation % 4) + 4) % 4
        
        switch self {
        case .i:
            // I-piece: horizontal or vertical line
            if r % 2 == 0 {
                return [
                    [false, false, false, false],
                    [true,  true,  true,  true],
                    [false, false, false, false],
                    [false, false, false, false]
                ]
            } else {
                return [
                    [false, false, true, false],
                    [false, false, true, false],
                    [false, false, true, false],
                    [false, false, true, false]
                ]
            }
            
        case .o:
            // O-piece: 2x2 square (no rotation change)
            return [
                [false, false, false, false],
                [false, true,  true,  false],
                [false, true,  true,  false],
                [false, false, false, false]
            ]
            
        case .t:
            // T-piece: T-shaped in 4 orientations
            switch r {
            case 0: // T pointing up
                return [
                    [false, false, false, false],
                    [true,  true,  true,  false],
                    [false, true,  false, false],
                    [false, false, false, false]
                ]
            case 1: // T pointing right
                return [
                    [false, true,  false, false],
                    [true,  true,  false, false],
                    [false, true,  false, false],
                    [false, false, false, false]
                ]
            case 2: // T pointing down
                return [
                    [false, true,  false, false],
                    [true,  true,  true,  false],
                    [false, false, false, false],
                    [false, false, false, false]
                ]
            case 3: // T pointing left
                return [
                    [false, true,  false, false],
                    [false, true,  true,  false],
                    [false, true,  false, false],
                    [false, false, false, false]
                ]
            default: return [[false]]
            }
            
        case .s:
            // S-piece: zigzag right
            if r % 2 == 0 {
                return [
                    [false, false, false, false],
                    [false, true,  true,  false],
                    [true,  true,  false, false],
                    [false, false, false, false]
                ]
            } else {
                return [
                    [false, true,  false, false],
                    [false, true,  true,  false],
                    [false, false, true,  false],
                    [false, false, false, false]
                ]
            }
            
        case .z:
            // Z-piece: zigzag left
            if r % 2 == 0 {
                return [
                    [false, false, false, false],
                    [true,  true,  false, false],
                    [false, true,  true,  false],
                    [false, false, false, false]
                ]
            } else {
                return [
                    [false, false, true, false],
                    [false, true,  true, false],
                    [false, true,  false, false],
                    [false, false, false, false]
                ]
            }
            
        case .j:
            // J-piece: L mirror
            switch r {
            case 0:
                return [
                    [false, false, false, false],
                    [true,  true,  true,  false],
                    [false, false, true,  false],
                    [false, false, false, false]
                ]
            case 1:
                return [
                    [false, true,  false, false],
                    [false, true,  false, false],
                    [true,  true,  false, false],
                    [false, false, false, false]
                ]
            case 2:
                return [
                    [true,  false, false, false],
                    [true,  true,  true,  false],
                    [false, false, false, false],
                    [false, false, false, false]
                ]
            case 3:
                return [
                    [false, true,  true,  false],
                    [false, true,  false, false],
                    [false, true,  false, false],
                    [false, false, false, false]
                ]
            default: return [[false]]
            }
            
        case .l:
            // L-piece: normal L
            switch r {
            case 0:
                return [
                    [false, false, false, false],
                    [true,  true,  true,  false],
                    [true,  false, false, false],
                    [false, false, false, false]
                ]
            case 1:
                return [
                    [true,  true,  false, false],
                    [false, true,  false, false],
                    [false, true,  false, false],
                    [false, false, false, false]
                ]
            case 2:
                return [
                    [false, false, true,  false],
                    [true,  true,  true,  false],
                    [false, false, false, false],
                    [false, false, false, false]
                ]
            case 3:
                return [
                    [false, true,  false, false],
                    [false, true,  false, false],
                    [false, true,  true,  false],
                    [false, false, false, false]
                ]
            default: return [[false]]
            }
        }
    }
}
