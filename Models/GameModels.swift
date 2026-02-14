import SwiftUI

/// Represents a single block/cell on the game board
struct Block: Identifiable, Equatable {
    let id = UUID()
    var isFilled: Bool
    var color: Color
    
    static let empty = Block(isFilled: false, color: .clear)
}

/// Represents a falling piece with its type, position, and rotation
struct ActivePiece: Equatable {
    let type: TetrominoType
    var x: Int
    var y: Int
    var rotation: Int
    
    init(type: TetrominoType, x: Int, y: Int, rotation: Int = 0) {
        self.type = type
        self.x = x
        self.y = y
        self.rotation = rotation
    }
    
    /// Returns the current block pattern for this piece
    var blocks: [[Bool]] {
        return type.blocks(for: rotation)
    }
    
    /// Returns the color of this piece
    var color: Color {
        return type.color
    }
    
    /// Creates a rotated version of this piece (without modifying original)
    func rotated(clockwise: Bool = true) -> ActivePiece {
        return ActivePiece(
            type: type,
            x: x,
            y: y,
            rotation: clockwise ? rotation + 1 : rotation - 1
        )
    }
    
    /// Creates a moved version of this piece (without modifying original)
    func moved(dx: Int, dy: Int) -> ActivePiece {
        return ActivePiece(
            type: type,
            x: x + dx,
            y: y + dy,
            rotation: rotation
        )
    }
}

/// Game state enum to track current game status
enum GameState {
    case ready       // Initial state, waiting to start
    case playing
    case paused
    case gameOver
}

/// Constants for the game board dimensions
struct GameConstants {
    static let boardWidth = 10
    static let boardHeight = 20
    static let previewSize = 4
}
