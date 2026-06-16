import XCTest
@testable import TetrisEngine

final class SRSKickTests: XCTestCase {

    func testOPieceNeverKicks() {
        for from in RotationState.allCases {
            let to = from.rotated(clockwise: true)
            XCTAssertEqual(SRSKicks.offsets(kind: .o, from: from, to: to), [Coord(0, 0)])
        }
    }

    func testJLSTZSpawnToRightTable() {
        // Canonical y-up values from the SRS standard.
        let expected = [Coord(0,0), Coord(-1,0), Coord(-1,1), Coord(0,-2), Coord(-1,-2)]
        XCTAssertEqual(SRSKicks.offsets(kind: .t, from: .spawn, to: .right), expected)
    }

    func testIPieceSpawnToRightTable() {
        let expected = [Coord(0,0), Coord(-2,0), Coord(1,0), Coord(-2,-1), Coord(1,2)]
        XCTAssertEqual(SRSKicks.offsets(kind: .i, from: .spawn, to: .right), expected)
    }

    func testEveryTransitionHasFiveTests() {
        for kind in [TetrominoKind.t, .j, .l, .s, .z, .i] {
            for from in RotationState.allCases {
                for clockwise in [true, false] {
                    let to = from.rotated(clockwise: clockwise)
                    let offs = SRSKicks.offsets(kind: kind, from: from, to: to)
                    XCTAssertEqual(offs.count, 5, "\(kind) \(from)->\(to)")
                    XCTAssertEqual(offs.first, Coord(0, 0), "first test is always identity")
                }
            }
        }
    }

    func testTablesAreMirroredInverses() {
        // 0->R test 2 is (-1,0); the reverse R->0 test 2 should be (+1,0).
        let fwd = SRSKicks.offsets(kind: .t, from: .spawn, to: .right)[1]
        let rev = SRSKicks.offsets(kind: .t, from: .right, to: .spawn)[1]
        XCTAssertEqual(fwd, Coord(-1, 0))
        XCTAssertEqual(rev, Coord(1, 0))
    }
}
