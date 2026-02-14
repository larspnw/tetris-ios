import SwiftUI

/// Represents the game board and handles game logic
class Board {
    /// The 2D grid of blocks
    private var grid: [[Block]]
    
    /// Width of the board in blocks
    let width: Int
    
    /// Height of the board in blocks
    let height: Int
    
    init(width: Int = GameConstants.boardWidth, height: Int = GameConstants.boardHeight) {
        self.width = width
        self.height = height
        self.grid = Array(repeating: Array(repeating: Block.empty, count: width), count: height)
    }
    
    /// Access a block at the given coordinates
    subscript(x: Int, y: Int) -> Block {
        get {
            guard isValidPosition(x: x, y: y) else { return Block.empty }
            return grid[y][x]
        }
        set {
            guard isValidPosition(x: x, y: y) else { return }
            grid[y][x] = newValue
        }
    }
    
    /// Get a copy of the entire grid (for rendering)
    func getGrid() -> [[Block]] {
        return grid
    }
    
    /// Check if coordinates are within the board
    func isValidPosition(x: Int, y: Int) -> Bool {
        return x >= 0 && x < width && y >= 0 && y < height
    }
    
    /// Check if a piece can be placed at the given position
    func canPlacePiece(_ piece: ActivePiece) -> Bool {
        let blocks = piece.blocks
        
        for row in 0..<4 {
            for col in 0..<4 {
                if blocks[row][col] {
                    let boardX = piece.x + col
                    let boardY = piece.y + row
                    
                    // Check bounds
                    if boardX < 0 || boardX >= width || boardY >= height {
                        return false
                    }
                    
                    // Check collision with existing blocks (only if within bounds)
                    if boardY >= 0 && grid[boardY][boardX].isFilled {
                        return false
                    }
                }
            }
        }
        return true
    }
    
    /// Lock a piece into place on the board
    func lockPiece(_ piece: ActivePiece) {
        let blocks = piece.blocks
        
        for row in 0..<4 {
            for col in 0..<4 {
                if blocks[row][col] {
                    let boardX = piece.x + col
                    let boardY = piece.y + row
                    
                    if isValidPosition(x: boardX, y: boardY) {
                        grid[boardY][boardX] = Block(isFilled: true, color: piece.color)
                    }
                }
            }
        }
    }
    
    /// Check if the piece is at the spawn position and would collide
    func isGameOver(_ piece: ActivePiece) -> Bool {
        return !canPlacePiece(piece)
    }
    
    /// Clear completed lines and return the number of lines cleared
    func clearLines() -> Int {
        var linesCleared = 0
        var newGrid: [[Block]] = []
        
        // Keep only rows that are not complete
        for row in grid {
            let isComplete = row.allSatisfy { $0.isFilled }
            if !isComplete {
                newGrid.append(row)
            } else {
                linesCleared += 1
            }
        }
        
        // Add empty rows at the top for cleared lines
        for _ in 0..<linesCleared {
            newGrid.insert(Array(repeating: Block.empty, count: width), at: 0)
        }
        
        grid = newGrid
        return linesCleared
    }
    
    /// Reset the board to empty state
    func reset() {
        grid = Array(repeating: Array(repeating: Block.empty, count: width), count: height)
    }
    
    /// Get a merged grid view that includes both locked blocks and the active piece
    /// This is used for rendering the complete game state
    func getMergedGrid(with piece: ActivePiece) -> [[Block]] {
        var merged = grid
        let blocks = piece.blocks
        
        for row in 0..<4 {
            for col in 0..<4 {
                if blocks[row][col] {
                    let boardX = piece.x + col
                    let boardY = piece.y + row
                    
                    if isValidPosition(x: boardX, y: boardY) {
                        merged[boardY][boardX] = Block(isFilled: true, color: piece.color)
                    }
                }
            }
        }
        
        return merged
    }
}
