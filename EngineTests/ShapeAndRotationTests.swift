import XCTest
@testable import TetrisEngine

final class ShapeAndRotationTests: XCTestCase {

    func testEveryPieceHasFourCellsInEveryState() {
        for kind in TetrominoKind.allCases {
            for state in RotationState.allCases {
                XCTAssertEqual(TetrominoShapes.cells(kind, state).count, 4,
                               "\(kind) \(state) should have 4 cells")
            }
        }
    }

    func testCellsStayWithinBoundingBox() {
        for kind in TetrominoKind.allCases {
            let box = TetrominoShapes.boxSize(kind)
            for state in RotationState.allCases {
                for c in TetrominoShapes.cells(kind, state) {
                    XCTAssertTrue((0..<box).contains(c.x) && (0..<box).contains(c.y),
                                  "\(kind) \(state) cell \(c) out of \(box)x\(box) box")
                }
            }
        }
    }

    func testOPieceDoesNotChangeShape() {
        let spawn = Set(TetrominoShapes.cells(.o, .spawn).map { "\($0.x),\($0.y)" })
        for state in RotationState.allCases {
            let s = Set(TetrominoShapes.cells(.o, state).map { "\($0.x),\($0.y)" })
            XCTAssertEqual(spawn, s)
        }
    }

    func testRotationStateCycle() {
        XCTAssertEqual(RotationState.spawn.rotated(clockwise: true), .right)
        XCTAssertEqual(RotationState.right.rotated(clockwise: true), .flip)
        XCTAssertEqual(RotationState.flip.rotated(clockwise: true), .left)
        XCTAssertEqual(RotationState.left.rotated(clockwise: true), .spawn)
        XCTAssertEqual(RotationState.spawn.rotated(clockwise: false), .left)
        XCTAssertEqual(RotationState.left.rotated(clockwise: false), .flip)
    }

    func testPieceCellsAreOriginTranslated() {
        let p = Piece(kind: .t, state: .spawn, origin: Coord(4, 5))
        let expected = TetrominoShapes.cells(.t, .spawn).map { Coord($0.x + 4, $0.y + 5) }
        XCTAssertEqual(p.cells, expected)
    }

    func testMovedAndWithState() {
        let p = Piece(kind: .j, state: .spawn, origin: Coord(3, 0))
        XCTAssertEqual(p.moved(dx: 2, dy: 1).origin, Coord(5, 1))
        XCTAssertEqual(p.withState(.right).state, .right)
        XCTAssertEqual(p.withState(.right).origin, Coord(3, 0)) // unchanged
    }
}
