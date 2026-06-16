import Foundation

/// Classification of a T-spin at lock time.
public enum TSpin: Equatable, Sendable {
    case none
    case mini
    case full
}

public enum TSpinDetector {
    /// Corner offsets of the T's 3x3 bounding box (y-down): TL, TR, BL, BR.
    private static let cornerOffsets = [Coord(0,0), Coord(2,0), Coord(0,2), Coord(2,2)]

    /// Which two corners are "front" (toward the T's point) for each state. Indices into
    /// `cornerOffsets`. spawn=point-up→top, right→right, flip→bottom, left→left.
    private static func frontIndices(_ state: RotationState) -> [Int] {
        switch state {
        case .spawn: return [0, 1] // top
        case .right: return [1, 3] // right
        case .flip:  return [2, 3] // bottom
        case .left:  return [0, 2] // left
        }
    }

    /// Detect a T-spin for a freshly-placed `piece` on `field`.
    /// - lastActionWasRotation: only rotations can produce a T-spin.
    /// - usedLongKick: the rotation used the 5th SRS test (the 1×2 kick) → always full.
    public static func detect(piece: Piece,
                              field: Playfield,
                              lastActionWasRotation: Bool,
                              usedLongKick: Bool) -> TSpin {
        guard piece.kind == .t, lastActionWasRotation else { return .none }

        let occupied = cornerOffsets.map { off -> Bool in
            let c = piece.origin + off
            return !field.inBounds(c) || field.isOccupied(c)
        }
        let total = occupied.filter { $0 }.count
        guard total >= 3 else { return .none }

        if usedLongKick { return .full }

        let front = frontIndices(piece.state)
        let frontOccupied = front.filter { occupied[$0] }.count
        return frontOccupied == 2 ? .full : .mini
    }
}
