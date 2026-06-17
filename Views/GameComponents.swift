import SwiftUI

/// One rendered cell of the visible board.
struct RenderCell: Equatable {
    var color: Color?
    var ghost: Bool
}

enum BoardRenderer {
    /// Build the visible grid (locked stack + ghost + current piece) for rendering.
    static func grid(_ engine: GameEngine, ghostOn: Bool) -> [[RenderCell]] {
        let f = engine.field
        var grid = Array(repeating: Array(repeating: RenderCell(color: nil, ghost: false), count: f.width),
                         count: f.visibleHeight)

        for r in 0..<f.visibleHeight {
            let fy = f.bufferHeight + r
            for x in 0..<f.width where f.cells[fy][x] != nil {
                grid[r][x].color = f.cells[fy][x]!.color
            }
        }
        if ghostOn {
            for c in engine.ghost.cells {
                let r = c.y - f.bufferHeight
                if r >= 0, r < f.visibleHeight, c.x >= 0, c.x < f.width, grid[r][c.x].color == nil {
                    grid[r][c.x] = RenderCell(color: engine.current.kind.color, ghost: true)
                }
            }
        }
        for c in engine.current.cells {
            let r = c.y - f.bufferHeight
            if r >= 0, r < f.visibleHeight, c.x >= 0, c.x < f.width {
                grid[r][c.x] = RenderCell(color: engine.current.kind.color, ghost: false)
            }
        }
        return grid
    }
}

/// A single board cell.
struct BlockView: View {
    let cell: RenderCell
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.16)
                .fill(fillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.16)
                        .stroke(strokeColor, lineWidth: cell.ghost ? 1.5 : 0.5)
                )
            if cell.color != nil, !cell.ghost {
                RoundedRectangle(cornerRadius: size * 0.12)
                    .fill(LinearGradient(colors: [.white.opacity(0.35), .clear],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .padding(size * 0.12)
            }
        }
        .frame(width: size, height: size)
    }

    private var fillColor: Color {
        guard let color = cell.color else { return Color.white.opacity(0.04) }
        return cell.ghost ? color.opacity(0.18) : color
    }
    private var strokeColor: Color {
        guard let color = cell.color else { return Color.white.opacity(0.06) }
        return cell.ghost ? color.opacity(0.7) : Color.black.opacity(0.25)
    }
}

/// The main playfield.
struct GameBoardView: View {
    let grid: [[RenderCell]]
    let cellSize: CGFloat
    var spacing: CGFloat = 1

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(0..<grid.count, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<grid[row].count, id: \.self) { col in
                        BlockView(cell: grid[row][col], size: cellSize)
                    }
                }
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.85)))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.15), lineWidth: 1.5))
    }
}

/// A small preview box for the hold slot or a next-queue entry.
struct PiecePreview: View {
    let kind: TetrominoKind?
    let cellSize: CGFloat
    var dimmed: Bool = false

    var body: some View {
        let cells = kind.map { TetrominoShapes.cells($0, .spawn) } ?? []
        let xs = cells.map { $0.x }, ys = cells.map { $0.y }
        let minX = xs.min() ?? 0, maxX = xs.max() ?? 0
        let minY = ys.min() ?? 0, maxY = ys.max() ?? 0
        let cols = max(1, maxX - minX + 1), rows = max(1, maxY - minY + 1)
        let occupied = Set(cells.map { Coord($0.x - minX, $0.y - minY) })

        return VStack(spacing: 1) {
            ForEach(0..<rows, id: \.self) { r in
                HStack(spacing: 1) {
                    ForEach(0..<cols, id: \.self) { c in
                        let on = occupied.contains(Coord(c, r))
                        RoundedRectangle(cornerRadius: cellSize * 0.16)
                            .fill(on ? (kind?.color ?? .clear).opacity(dimmed ? 0.4 : 1) : .clear)
                            .frame(width: cellSize, height: cellSize)
                    }
                }
            }
        }
        .frame(width: cellSize * 4.2, height: cellSize * 3.0)
    }
}

/// A labeled stat chip.
struct StatChip: View {
    let title: String
    let value: String
    var body: some View {
        VStack(spacing: 3) {
            Text(title).font(.caption2).fontWeight(.semibold).foregroundColor(.secondary)
            Text(value).font(.headline).fontWeight(.bold).monospacedDigit().foregroundColor(.white)
        }
        .frame(minWidth: 64)
        .padding(.vertical, 6).padding(.horizontal, 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.07)))
    }
}
