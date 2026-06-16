import XCTest
@testable import TetrisEngine

final class TSpinDetectionTests: XCTestCase {

    func testNotATSpinWithoutRotation() {
        var f = Playfield()
        let t = Piece(kind: .t, state: .flip, origin: Coord(0, 37))
        // Fill enough corners that it WOULD be a T-spin if rotation had happened.
        f.setCell(.i, at: Coord(0, 37))
        f.setCell(.i, at: Coord(2, 37))
        let result = TSpinDetector.detect(piece: t, field: f,
                                          lastActionWasRotation: false, usedLongKick: false)
        XCTAssertEqual(result, .none)
    }

    func testNonTPieceIsNeverTSpin() {
        let f = Playfield()
        let l = Piece(kind: .l, state: .spawn, origin: Coord(0, 37))
        XCTAssertEqual(TSpinDetector.detect(piece: l, field: f,
                                            lastActionWasRotation: true, usedLongKick: false), .none)
    }

    func testFullTSpinWithThreeCorners() {
        // T pointing down (state .flip) at the bottom-left. Box rows 37..39, cols 0..2.
        // Bottom corners (0,39),(2,39) are the "front" for .flip. Fill both + one back corner.
        var f = Playfield()
        let origin = Coord(0, 37)
        f.setCell(.i, at: origin + Coord(0, 2)) // bottom-left  (front)
        f.setCell(.i, at: origin + Coord(2, 2)) // bottom-right (front)
        f.setCell(.i, at: origin + Coord(0, 0)) // top-left     (back)
        let t = Piece(kind: .t, state: .flip, origin: origin)
        XCTAssertEqual(TSpinDetector.detect(piece: t, field: f,
                                            lastActionWasRotation: true, usedLongKick: false), .full)
    }

    func testMiniTSpinWithOneFrontCorner() {
        // T pointing up (state .spawn). Front corners are the TOP two. Fill both BACK
        // (bottom) corners + one FRONT → mini.
        var f = Playfield()
        let origin = Coord(0, 37)
        f.setCell(.i, at: origin + Coord(0, 2)) // bottom-left  (back)
        f.setCell(.i, at: origin + Coord(2, 2)) // bottom-right (back)
        f.setCell(.i, at: origin + Coord(0, 0)) // top-left     (front) — only one front
        let t = Piece(kind: .t, state: .spawn, origin: origin)
        XCTAssertEqual(TSpinDetector.detect(piece: t, field: f,
                                            lastActionWasRotation: true, usedLongKick: false), .mini)
    }

    func testLongKickForcesFullTSpin() {
        var f = Playfield()
        let origin = Coord(0, 37)
        // Only two back corners filled → would be insufficient/mini, but long kick forces full.
        f.setCell(.i, at: origin + Coord(0, 2))
        f.setCell(.i, at: origin + Coord(2, 2))
        f.setCell(.i, at: origin + Coord(0, 0))
        let t = Piece(kind: .t, state: .spawn, origin: origin)
        XCTAssertEqual(TSpinDetector.detect(piece: t, field: f,
                                            lastActionWasRotation: true, usedLongKick: true), .full)
    }

    func testFewerThanThreeCornersIsNotTSpin() {
        var f = Playfield()
        let origin = Coord(4, 20)
        f.setCell(.i, at: origin + Coord(0, 0)) // only one corner
        let t = Piece(kind: .t, state: .spawn, origin: origin)
        XCTAssertEqual(TSpinDetector.detect(piece: t, field: f,
                                            lastActionWasRotation: true, usedLongKick: false), .none)
    }
}
