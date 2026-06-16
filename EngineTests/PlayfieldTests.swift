import XCTest
@testable import TetrisEngine

final class PlayfieldTests: XCTestCase {

    func testDimensions() {
        let f = Playfield()
        XCTAssertEqual(f.width, 10)
        XCTAssertEqual(f.visibleHeight, 20)
        XCTAssertEqual(f.totalHeight, 40)
        XCTAssertTrue(f.isEmpty)
    }

    func testBoundsAndOccupancy() {
        var f = Playfield()
        XCTAssertFalse(f.inBounds(Coord(-1, 0)))
        XCTAssertFalse(f.inBounds(Coord(0, 40)))
        XCTAssertTrue(f.inBounds(Coord(0, 0)))
        f.setCell(.t, at: Coord(3, 39))
        XCTAssertTrue(f.isOccupied(Coord(3, 39)))
        XCTAssertFalse(f.isOccupied(Coord(3, 38)))
        XCTAssertFalse(f.isEmpty)
    }

    func testCollisionWithWallsFloorAndStack() {
        var f = Playfield()
        // Off the left wall.
        XCTAssertTrue(f.collides(Piece(kind: .o, origin: Coord(-1, 0))))
        // Off the right wall (O occupies cols origin+1..+2; width 10).
        XCTAssertTrue(f.collides(Piece(kind: .o, origin: Coord(9, 0))))
        // Below the floor.
        XCTAssertTrue(f.collides(Piece(kind: .o, origin: Coord(4, 40))))
        // Free space.
        XCTAssertFalse(f.collides(Piece(kind: .o, origin: Coord(4, 4))))
        // Onto a filled cell.
        f.setCell(.i, at: Coord(5, 5))
        XCTAssertTrue(f.collides(Piece(kind: .o, origin: Coord(4, 4))))
    }

    func testCellsAboveTopAreAllowed() {
        let f = Playfield()
        // y < 0 cells are permitted during play (buffer above the matrix).
        XCTAssertFalse(f.collides(Piece(kind: .i, origin: Coord(3, -2))))
    }

    func testClearSingleLine() {
        var f = Playfield()
        let row = 39
        for x in 0..<f.width { f.setCell(.z, at: Coord(x, row)) }
        f.setCell(.t, at: Coord(0, 38)) // a leftover above the cleared row
        let cleared = f.clearFullLines()
        XCTAssertEqual(cleared, [39])
        XCTAssertFalse(f.isRowFull(39))
        // The leftover should have fallen down one row.
        XCTAssertTrue(f.isOccupied(Coord(0, 39)))
    }

    func testClearFourLinesTetris() {
        var f = Playfield()
        for y in 36...39 {
            for x in 0..<f.width { f.setCell(.i, at: Coord(x, y)) }
        }
        let cleared = f.clearFullLines()
        XCTAssertEqual(cleared.count, 4)
        XCTAssertTrue(f.isEmpty)
    }

    func testDropDistanceAndGhost() {
        let f = Playfield()
        let piece = Piece(kind: .o, state: .spawn, origin: Coord(4, 0))
        // O fills rows origin+0..+1; bottom-most filled is origin.y+1. Floor at 39.
        // Ghost bottom row should reach 39 → origin.y becomes 38.
        let ghost = f.ghost(piece)
        XCTAssertEqual(ghost.origin.y, 38)
        XCTAssertEqual(f.dropDistance(piece), 38)
    }

    func testResetClearsField() {
        var f = Playfield()
        f.setCell(.t, at: Coord(0, 0))
        f.reset()
        XCTAssertTrue(f.isEmpty)
    }
}
