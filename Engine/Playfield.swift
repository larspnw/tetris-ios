import Foundation

/// The game matrix. Internally `totalHeight` rows tall (visible rows + a hidden buffer
/// above), `width` columns wide. Row 0 is the top. A cell is either empty (`nil`) or
/// occupied by a locked tetromino of some kind (used for coloring in the app layer).
public struct Playfield: Equatable, Sendable {
    public let width: Int
    public let visibleHeight: Int
    public let bufferHeight: Int
    public var totalHeight: Int { visibleHeight + bufferHeight }

    /// `cells[y][x]` — the locked stack. `nil` is empty.
    public private(set) var cells: [[TetrominoKind?]]

    public init(width: Int = 10, visibleHeight: Int = 20, bufferHeight: Int = 20) {
        self.width = width
        self.visibleHeight = visibleHeight
        self.bufferHeight = bufferHeight
        self.cells = Array(repeating: Array(repeating: nil, count: width),
                           count: visibleHeight + bufferHeight)
    }

    public func inBounds(_ c: Coord) -> Bool {
        c.x >= 0 && c.x < width && c.y >= 0 && c.y < totalHeight
    }

    public func isOccupied(_ c: Coord) -> Bool {
        guard inBounds(c) else { return false }
        return cells[c.y][c.x] != nil
    }

    /// True if `piece` cannot legally occupy its cells (out of bounds horizontally/below,
    /// or overlapping a locked cell). Cells above the top (y < 0) are allowed during play.
    public func collides(_ piece: Piece) -> Bool {
        for c in piece.cells {
            if c.x < 0 || c.x >= width || c.y >= totalHeight { return true }
            if c.y >= 0 && cells[c.y][c.x] != nil { return true }
        }
        return false
    }

    /// Set (or clear) a single cell. Used for garbage rows and tests.
    public mutating func setCell(_ kind: TetrominoKind?, at c: Coord) {
        guard inBounds(c) else { return }
        cells[c.y][c.x] = kind
    }

    /// Lock a piece's cells into the stack.
    public mutating func lock(_ piece: Piece) {
        for c in piece.cells where c.y >= 0 && c.y < totalHeight && c.x >= 0 && c.x < width {
            cells[c.y][c.x] = piece.kind
        }
    }

    public func isRowFull(_ y: Int) -> Bool {
        guard y >= 0 && y < totalHeight else { return false }
        return cells[y].allSatisfy { $0 != nil }
    }

    /// Remove all full rows, collapsing the stack downward. Returns the cleared row indices.
    @discardableResult
    public mutating func clearFullLines() -> [Int] {
        var cleared: [Int] = []
        var newRows: [[TetrominoKind?]] = []
        for y in 0..<totalHeight {
            if isRowFull(y) { cleared.append(y) }
            else { newRows.append(cells[y]) }
        }
        let emptyRow = Array<TetrominoKind?>(repeating: nil, count: width)
        while newRows.count < totalHeight { newRows.insert(emptyRow, at: 0) }
        cells = newRows
        return cleared
    }

    /// Drop distance (rows) until `piece` would rest on the stack/floor.
    public func dropDistance(_ piece: Piece) -> Int {
        var d = 0
        while !collides(piece.moved(dx: 0, dy: d + 1)) { d += 1 }
        return d
    }

    /// The piece resting at the bottom of its column (the ghost position).
    public func ghost(_ piece: Piece) -> Piece {
        piece.moved(dx: 0, dy: dropDistance(piece))
    }

    /// True when the whole field is empty (used for perfect-clear detection).
    public var isEmpty: Bool {
        cells.allSatisfy { row in row.allSatisfy { $0 == nil } }
    }

    public mutating func reset() {
        cells = Array(repeating: Array(repeating: nil, count: width), count: totalHeight)
    }
}
