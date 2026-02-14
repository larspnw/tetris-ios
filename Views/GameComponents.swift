import SwiftUI

/// A single block cell view
struct BlockView: View {
    let block: Block
    let size: CGFloat
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.15)
                .fill(block.isFilled ? block.color : Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.15)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                )
            
            // Add a subtle inner highlight for filled blocks
            if block.isFilled {
                RoundedRectangle(cornerRadius: size * 0.1)
                    .fill(LinearGradient(
                        colors: [.white.opacity(0.3), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .padding(size * 0.1)
            }
        }
        .frame(width: size, height: size)
    }
}

/// The main game board view showing the 10x20 grid
struct GameBoardView: View {
    let grid: [[Block]]
    let cellSize: CGFloat
    
    var body: some View {
        VStack(spacing: 1) {
            ForEach(0..<grid.count, id: \.self) { row in
                HStack(spacing: 1) {
                    ForEach(0..<grid[row].count, id: \.self) { col in
                        BlockView(block: grid[row][col], size: cellSize)
                    }
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.4), lineWidth: 2)
        )
    }
}

/// Preview view showing the next piece
struct NextPieceView: View {
    let blocks: [[Bool]]
    let color: Color
    let cellSize: CGFloat
    
    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<4, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<4, id: \.self) { col in
                        if blocks[row][col] {
                            RoundedRectangle(cornerRadius: cellSize * 0.15)
                                .fill(color)
                                .frame(width: cellSize, height: cellSize)
                                .overlay(
                                    RoundedRectangle(cornerRadius: cellSize * 0.1)
                                        .fill(LinearGradient(
                                            colors: [.white.opacity(0.3), .clear],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .padding(cellSize * 0.1)
                                )
                        } else {
                            Color.clear
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.15))
        )
    }
}

/// Score display component
struct ScoreView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .monospacedDigit()
        }
        .frame(minWidth: 80)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.15))
        )
    }
}

/// Game over overlay
struct GameOverOverlay: View {
    let score: Int
    let level: Int
    let linesCleared: Int
    let onRestart: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("GAME OVER")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                VStack(spacing: 8) {
                    Text("Final Score: \(score)")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text("Level: \(level)")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Lines: \(linesCleared)")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Button(action: onRestart) {
                    Text("Play Again")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green)
                        )
                }
                .padding(.top, 16)
            }
        }
    }
}

/// Pause overlay
struct PauseOverlay: View {
    let onResume: () -> Void
    let onRestart: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("PAUSED")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                VStack(spacing: 12) {
                    Button(action: onResume) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Resume")
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: 200)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                        )
                    }
                    
                    Button(action: onRestart) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Restart")
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: 200)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange)
                        )
                    }
                }
            }
        }
    }
}

/// Touch controls indicator overlay
struct ControlsHintView: View {
    var body: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.left")
                    Text("Swipe")
                        .font(.caption2)
                }
                
                VStack(spacing: 4) {
                    Image(systemName: "hand.tap")
                    Text("Tap to Rotate")
                        .font(.caption2)
                }
                
                VStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                    Text("Swipe Down")
                        .font(.caption2)
                }
            }
            .foregroundColor(.white.opacity(0.6))
            .padding(.bottom, 8)
        }
    }
}
