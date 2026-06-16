import Foundation

/// The seven standard tetrominoes. Pure data — no SwiftUI/UIKit here so the engine
/// stays testable on any platform. Color is mapped in the app layer.
public enum TetrominoKind: Int, CaseIterable, Equatable, Sendable {
    case i, o, t, s, z, j, l
}

/// A rotation state, named per the SRS convention.
public enum RotationState: Int, CaseIterable, Equatable, Sendable {
    case spawn = 0   // 0
    case right = 1   // R (clockwise from spawn)
    case flip = 2    // 2 (180°)
    case left = 3    // L (counter-clockwise from spawn)

    public func rotated(clockwise: Bool) -> RotationState {
        let next = (rawValue + (clockwise ? 1 : 3)) % 4
        return RotationState(rawValue: next)!
    }
}

/// An integer board coordinate. `x` increases rightward, `y` increases DOWNWARD
/// (row 0 is the top), matching the on-screen grid and array indexing.
public struct Coord: Equatable, Hashable, Sendable {
    public var x: Int
    public var y: Int
    public init(_ x: Int, _ y: Int) { self.x = x; self.y = y }

    public static func + (a: Coord, b: Coord) -> Coord { Coord(a.x + b.x, a.y + b.y) }
}
