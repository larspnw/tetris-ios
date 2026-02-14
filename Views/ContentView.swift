import SwiftUI

/// Main game view containing the board, score, and controls
struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // Gesture state for tracking swipe direction
    @State private var dragOffset: CGSize = .zero
    
    // Configuration
    private let cellSize: CGFloat = 28
    private let swipeThreshold: CGFloat = 20
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Header with title, back button, and pause button
                    HStack {
                        Button(action: {
                            viewModel.cleanup()
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                )
                        }
                        
                        Text("TETRIS")
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Pause/Play button
                        Button(action: {
                            viewModel.togglePause()
                        }) {
                            Image(systemName: viewModel.gameState == .playing ? "pause.circle.fill" : "play.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Score, time, and info row
                    HStack(spacing: 12) {
                        VStack(spacing: 8) {
                            ScoreView(title: "SCORE", value: "\(viewModel.score)")
                            ScoreView(title: "TIME", value: viewModel.formattedSessionTime())
                        }
                        
                        Spacer()
                        
                        // Next piece preview
                        VStack(spacing: 4) {
                            Text("NEXT")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            NextPieceView(
                                blocks: viewModel.getNextPieceBlocks(),
                                color: viewModel.nextPieceColor,
                                cellSize: cellSize * 0.6
                            )
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 8) {
                            ScoreView(title: "LEVEL", value: "\(viewModel.level)")
                            ScoreView(title: "LINES", value: "\(viewModel.linesCleared)")
                        }
                    }
                    .padding(.horizontal)
                    
                    // Game board with gesture handling
                    GameBoardView(
                        grid: viewModel.getDisplayGrid(),
                        cellSize: cellSize
                    )
                    .gesture(
                        DragGesture(minimumDistance: 10)
                            .onChanged { value in
                                dragOffset = value.translation
                            }
                            .onEnded { value in
                                handleSwipe(value: value)
                                dragOffset = .zero
                            }
                    )
                    .onTapGesture {
                        viewModel.rotatePiece()
                    }
                    
                    // Controls hint
                    if viewModel.gameState == .playing {
                        ControlsHintView()
                            .padding(.bottom, 20)
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
                
                // Pause overlay
                if viewModel.gameState == .paused {
                    PauseOverlay(
                        onResume: { viewModel.resumeGame() },
                        onRestart: { viewModel.startGame() }
                    )
                }
                
                // Game over overlay
                if viewModel.gameState == .gameOver {
                    GameOverOverlay(
                        score: viewModel.score,
                        level: viewModel.level,
                        linesCleared: viewModel.linesCleared,
                        onRestart: { viewModel.startGame() }
                    )
                }
            }
        }
        .onAppear {
            // Start the game when view appears
            viewModel.startGame()
        }
        .onDisappear {
            // Clean up and save stats when leaving
            viewModel.cleanup()
        }
    }
    
    // MARK: - Gesture Handling
    
    private func handleSwipe(value: DragGesture.Value) {
        let horizontal = value.translation.width
        let vertical = value.translation.height
        
        // Determine if horizontal or vertical swipe was dominant
        if abs(horizontal) > abs(vertical) {
            // Horizontal swipe - move left or right
            if horizontal > swipeThreshold {
                viewModel.movePieceRight()
            } else if horizontal < -swipeThreshold {
                viewModel.movePieceLeft()
            }
        } else {
            // Vertical swipe - soft drop
            if vertical > swipeThreshold {
                viewModel.movePieceDown()
            }
        }
    }
}

#Preview {
    ContentView()
}
