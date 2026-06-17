import Foundation

/// Super Rotation System wall-kick data.
///
/// Offsets are stored in the standard **y-UP** convention exactly as published on the
/// Tetris wiki / Hard Drop, so they can be checked against the reference by eye.
/// `Engine` applies them to the y-DOWN board by negating the y component.
public enum SRSKicks {

    /// Candidate offsets (5 tests) for rotating `from` -> `to`, for the given piece.
    /// The O piece never kicks (returns a single no-op test).
    public static func offsets(kind: TetrominoKind,
                               from: RotationState,
                               to: RotationState) -> [Coord] {
        if kind == .o { return [Coord(0, 0)] }
        let table = (kind == .i) ? iKicks : jlstzKicks
        return table[Key(from: from, to: to)] ?? [Coord(0, 0)]
    }

    private struct Key: Hashable { let from: RotationState; let to: RotationState }

    // JLSTZ kicks (y-up).
    private static let jlstzKicks: [Key: [Coord]] = [
        Key(from: .spawn, to: .right): [Coord(0,0), Coord(-1,0), Coord(-1,1),  Coord(0,-2), Coord(-1,-2)],
        Key(from: .right, to: .spawn): [Coord(0,0), Coord(1,0),  Coord(1,-1),  Coord(0,2),  Coord(1,2)],
        Key(from: .right, to: .flip):  [Coord(0,0), Coord(1,0),  Coord(1,-1),  Coord(0,2),  Coord(1,2)],
        Key(from: .flip,  to: .right): [Coord(0,0), Coord(-1,0), Coord(-1,1),  Coord(0,-2), Coord(-1,-2)],
        Key(from: .flip,  to: .left):  [Coord(0,0), Coord(1,0),  Coord(1,1),   Coord(0,-2), Coord(1,-2)],
        Key(from: .left,  to: .flip):  [Coord(0,0), Coord(-1,0), Coord(-1,-1), Coord(0,2),  Coord(-1,2)],
        Key(from: .left,  to: .spawn): [Coord(0,0), Coord(-1,0), Coord(-1,-1), Coord(0,2),  Coord(-1,2)],
        Key(from: .spawn, to: .left):  [Coord(0,0), Coord(1,0),  Coord(1,1),   Coord(0,-2), Coord(1,-2)],
    ]

    // I-piece kicks (y-up).
    private static let iKicks: [Key: [Coord]] = [
        Key(from: .spawn, to: .right): [Coord(0,0), Coord(-2,0), Coord(1,0),  Coord(-2,-1), Coord(1,2)],
        Key(from: .right, to: .spawn): [Coord(0,0), Coord(2,0),  Coord(-1,0), Coord(2,1),   Coord(-1,-2)],
        Key(from: .right, to: .flip):  [Coord(0,0), Coord(-1,0), Coord(2,0),  Coord(-1,2),  Coord(2,-1)],
        Key(from: .flip,  to: .right): [Coord(0,0), Coord(1,0),  Coord(-2,0), Coord(1,-2),  Coord(-2,1)],
        Key(from: .flip,  to: .left):  [Coord(0,0), Coord(2,0),  Coord(-1,0), Coord(2,1),   Coord(-1,-2)],
        Key(from: .left,  to: .flip):  [Coord(0,0), Coord(-2,0), Coord(1,0),  Coord(-2,-1), Coord(1,2)],
        Key(from: .left,  to: .spawn): [Coord(0,0), Coord(1,0),  Coord(-2,0), Coord(1,-2),  Coord(-2,1)],
        Key(from: .spawn, to: .left):  [Coord(0,0), Coord(-1,0), Coord(2,0),  Coord(-1,2),  Coord(2,-1)],
    ]
}
