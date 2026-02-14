import SwiftUI

/// Main game view containing the board, score, and controls
struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // Gesture state for tracking swipe direction
    @State private var dragOffset: CGSize = .zero
    @State private var showSettings = false
    
    // Configuration
    private let swipeThreshold: CGFloat = 20
    
    // Board dimensions
    private let boardWidth = GameConstants.boardWidth
    private let boardHeight = GameConstants.boardHeight
    private let cellSpacing: CGFloat = 1
    private let boardPadding: CGFloat = 4
    
    /// Calculate the optimal cell size to fit the board within available space
    private func calculateCellSize(availableHeight: CGFloat) -> CGFloat {
        // Calculate space needed for non-board elements (approximate)
        let headerHeight: CGFloat = 120  // Top bar + stats
        let controlsHeight: CGFloat = 80 // Controls hint + padding
        let safeAreaPadding: CGFloat = 60 // Extra padding for safe areas
        
        let availableForBoard = availableHeight - headerHeight - controlsHeight - safeAreaPadding
        
        // Calculate cell size: (available height - spacing - padding) / number of rows
        let totalSpacing = CGFloat(boardHeight - 1) * cellSpacing
        let totalPadding = boardPadding * 2
        let maxCellSize = (availableForBoard - totalSpacing - totalPadding) / CGFloat(boardHeight)
        
        // Also consider width constraint
        let screenWidth = UIScreen.main.bounds.width - 32 // Side padding
        let maxCellSizeFromWidth = (screenWidth - totalSpacing - totalPadding) / CGFloat(boardWidth)
        
        // Return the smaller of the two, with a reasonable min/max
        return min(max(min(maxCellSize, maxCellSizeFromWidth), 14), 32)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let cellSize = calculateCellSize(availableHeight: geometry.size.height)
            
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 12) {
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
                        
                        // Settings button
                        Button(action: {
                            viewModel.pauseGame()
                            showSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding(8)
                        }
                        
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
                                cellSize: max(cellSize * 0.55, 14)
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
                        cellSize: cellSize,
                        spacing: cellSpacing,
                        padding: boardPadding
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
                            .padding(.bottom, 8)
                    }
                    
                    Spacer(minLength: 8)
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
        .sheet(isPresented: $showSettings, onDismiss: {
            // Resume game when settings is dismissed (if it was playing)
            if viewModel.gameState == .paused {
                viewModel.resumeGame()
            }
        }) {
            SettingsView()
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
