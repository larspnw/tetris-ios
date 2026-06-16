import Foundation

/// A live, falling piece: its kind, rotation, and origin on the board.
public struct Piece: Equatable, Sendable {
    public let kind: TetrominoKind
    public var state: RotationState
    public var origin: Coord   // top-left of the bounding box, in board coords

    public init(kind: TetrominoKind, state: RotationState = .spawn, origin: Coord) {
        self.kind = kind
        self.state = state
        self.origin = origin
    }

    /// Absolute board coordinates of the four occupied cells.
    public var cells: [Coord] {
        TetrominoShapes.cells(kind, state).map { $0 + origin }
    }

    public func moved(dx: Int, dy: Int) -> Piece {
        var p = self
        p.origin = Coord(origin.x + dx, origin.y + dy)
        return p
    }

    public func withState(_ s: RotationState) -> Piece {
        var p = self
        p.state = s
        return p
    }
}
