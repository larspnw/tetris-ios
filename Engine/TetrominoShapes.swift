import Foundation

/// SRS-correct cell layouts for every piece in every rotation state.
///
/// Cells are offsets from the piece's origin (top-left of its bounding box),
/// in y-DOWN board coordinates. These are the canonical Super Rotation System
/// "true rotation" shapes. The O piece does not change between states.
public enum TetrominoShapes {

    /// The four occupied cells of `kind` in rotation `state`, as origin offsets.
    public static func cells(_ kind: TetrominoKind, _ state: RotationState) -> [Coord] {
        table[kind]![state.rawValue]
    }

    /// Width of the bounding box used for each kind (for spawn centering & T-spin corners).
    public static func boxSize(_ kind: TetrominoKind) -> Int {
        switch kind {
        case .i: return 4
        case .o: return 2
        default: return 3
        }
    }

    // [kind][rotationRawValue] -> 4 cells
    private static let table: [TetrominoKind: [[Coord]]] = [
        .i: [
            [Coord(0,1), Coord(1,1), Coord(2,1), Coord(3,1)], // spawn
            [Coord(2,0), Coord(2,1), Coord(2,2), Coord(2,3)], // R
            [Coord(0,2), Coord(1,2), Coord(2,2), Coord(3,2)], // 2
            [Coord(1,0), Coord(1,1), Coord(1,2), Coord(1,3)], // L
        ],
        .o: [
            [Coord(0,0), Coord(1,0), Coord(0,1), Coord(1,1)],
            [Coord(0,0), Coord(1,0), Coord(0,1), Coord(1,1)],
            [Coord(0,0), Coord(1,0), Coord(0,1), Coord(1,1)],
            [Coord(0,0), Coord(1,0), Coord(0,1), Coord(1,1)],
        ],
        .t: [
            [Coord(1,0), Coord(0,1), Coord(1,1), Coord(2,1)], // spawn (point up)
            [Coord(1,0), Coord(1,1), Coord(2,1), Coord(1,2)], // R (point right)
            [Coord(0,1), Coord(1,1), Coord(2,1), Coord(1,2)], // 2 (point down)
            [Coord(1,0), Coord(0,1), Coord(1,1), Coord(1,2)], // L (point left)
        ],
        .j: [
            [Coord(0,0), Coord(0,1), Coord(1,1), Coord(2,1)],
            [Coord(1,0), Coord(2,0), Coord(1,1), Coord(1,2)],
            [Coord(0,1), Coord(1,1), Coord(2,1), Coord(2,2)],
            [Coord(1,0), Coord(1,1), Coord(0,2), Coord(1,2)],
        ],
        .l: [
            [Coord(2,0), Coord(0,1), Coord(1,1), Coord(2,1)],
            [Coord(1,0), Coord(1,1), Coord(1,2), Coord(2,2)],
            [Coord(0,1), Coord(1,1), Coord(2,1), Coord(0,2)],
            [Coord(0,0), Coord(1,0), Coord(1,1), Coord(1,2)],
        ],
        .s: [
            [Coord(1,0), Coord(2,0), Coord(0,1), Coord(1,1)],
            [Coord(1,0), Coord(1,1), Coord(2,1), Coord(2,2)],
            [Coord(1,1), Coord(2,1), Coord(0,2), Coord(1,2)],
            [Coord(0,0), Coord(0,1), Coord(1,1), Coord(1,2)],
        ],
        .z: [
            [Coord(0,0), Coord(1,0), Coord(1,1), Coord(2,1)],
            [Coord(2,0), Coord(1,1), Coord(2,1), Coord(1,2)],
            [Coord(0,1), Coord(1,1), Coord(1,2), Coord(2,2)],
            [Coord(1,0), Coord(0,1), Coord(1,1), Coord(0,2)],
        ],
    ]
}
