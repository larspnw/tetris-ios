import SwiftUI
import Combine

/// ViewModel that manages the game state and logic
class GameViewModel: ObservableObject {
    
    // MARK: - Published Properties (UI will react to these)
    
    /// Current game board with locked pieces
    @Published private(set) var board: Board
    
    /// The currently falling piece
    @Published private(set) var currentPiece: ActivePiece
    
    /// The next piece that will appear
    @Published private(set) var nextPieceType: TetrominoType
    
    /// Current game state
    @Published private(set) var gameState: GameState = .ready
    
    /// Player's current score
    @Published private(set) var score: Int = 0
    
    /// Number of lines cleared
    @Published private(set) var linesCleared: Int = 0
    
    /// Current level (affects fall speed)
    @Published private(set) var level: Int = 1
    
    /// Current session time in seconds
    @Published private(set) var sessionTime: TimeInterval = 0
    
    /// Whether the game is currently running
    private var isGameRunning: Bool { gameState == .playing }
    
    // MARK: - Private Properties
    
    /// Timer for automatic piece falling
    private var gameTimer: AnyCancellable?
    
    /// Timer for tracking session duration
    private var sessionTimer: AnyCancellable?
    
    /// Random generator for pieces
    private var pieceBag: [TetrominoType] = []
    
    /// Reference to settings manager for drop speed
    private let settings = SettingsManager.shared

    /// Whether the player is holding to fast drop
    private var fastDropActive = false

    /// When the current piece was spawned (for timing bonus)
    private var pieceSpawnTime: Date?

    /// Base fall interval in seconds (decreases as level increases and applies speed setting)
    private var fallInterval: TimeInterval {
        if fastDropActive { return 0.05 }
        let baseInterval = 1.0 * settings.speedMultiplier
        let levelMultiplier = Double(level - 1) * 0.08 * settings.speedMultiplier
        return max(0.05, baseInterval - levelMultiplier)
    }
    
    // MARK: - Initialization
    
    init() {
        self.board = Board()
        self.nextPieceType = Self.randomPiece()
        self.currentPiece = Self.spawnPiece(type: Self.randomPiece())
        // Don't auto-start - wait for user to start from menu
    }
    
    // MARK: - Game Control
    
    /// Start or restart the game
    func startGame() {
        // Save any previous session time before resetting
        if sessionTime > 0 {
            StatsManager.shared.addTimePlayed(sessionTime)
        }
        
        board.reset()
        score = 0
        linesCleared = 0
        level = 1
        sessionTime = 0
        gameState = .playing
        pieceBag = []
        fastDropActive = false
        
        nextPieceType = getNextPieceFromBag()
        currentPiece = spawnNewPiece()
        
        startGameTimer()
        startSessionTimer()
    }
    
    /// Pause the game
    func pauseGame() {
        guard gameState == .playing else { return }
        gameState = .paused
        stopGameTimer()
        stopSessionTimer()
    }
    
    /// Resume the game
    func resumeGame() {
        guard gameState == .paused else { return }
        gameState = .playing
        startGameTimer()
        startSessionTimer()
    }
    
    /// Toggle pause state
    func togglePause() {
        if gameState == .playing {
            pauseGame()
        } else if gameState == .paused {
            resumeGame()
        }
    }
    
    /// End the game
    private func gameOver() {
        gameState = .gameOver
        stopGameTimer()
        stopSessionTimer()
        
        // Update statistics
        StatsManager.shared.updateHighScore(score)
        StatsManager.shared.addTimePlayed(sessionTime)
    }
    
    /// Clean up when leaving the game (e.g., returning to menu)
    func cleanup() {
        stopGameTimer()
        stopSessionTimer()
        
        // Save session time if game was in progress
        if sessionTime > 0 && (gameState == .playing || gameState == .paused) {
            StatsManager.shared.addTimePlayed(sessionTime)
        }
    }
    
    // MARK: - Session Timer
    
    private func startSessionTimer() {
        stopSessionTimer()
        
        sessionTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.sessionTime += 1.0
            }
    }
    
    private func stopSessionTimer() {
        sessionTimer?.cancel()
        sessionTimer = nil
    }
    
    /// Format session time for display (mm:ss)
    func formattedSessionTime() -> String {
        let minutes = Int(sessionTime) / 60
        let seconds = Int(sessionTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Game Timer
    
    private func startGameTimer() {
        stopGameTimer()
        
        gameTimer = Timer.publish(every: fallInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.gameTick()
            }
    }
    
    private func stopGameTimer() {
        gameTimer?.cancel()
        gameTimer = nil
    }
    
    /// Called on each timer tick - moves piece down
    private func gameTick() {
        guard isGameRunning else { return }
        movePieceDown()
    }
    
    /// Restart timer when level changes (to update speed)
    private func updateTimerForLevel() {
        guard isGameRunning else { return }
        startGameTimer()
    }
    
    /// Call this when speed settings change to apply immediately
    func applySpeedSetting() {
        guard isGameRunning else { return }
        startGameTimer()
    }

    /// Enable or disable fast drop (triggered by long press)
    func setFastDrop(_ active: Bool) {
        guard isGameRunning else { return }
        fastDropActive = active
        startGameTimer()
    }
    
    // MARK: - Piece Management
    
    /// Generate a random piece type using the 7-bag system for fairness
    private static func randomPiece() -> TetrominoType {
        return TetrominoType.allCases.randomElement()!
    }
    
    /// Get the next piece from the bag, refilling if empty
    private func getNextPieceFromBag() -> TetrominoType {
        if pieceBag.isEmpty {
            // Create a new bag with all 7 pieces shuffled
            pieceBag = TetrominoType.allCases.shuffled()
        }
        return pieceBag.removeFirst()
    }
    
    /// Spawn a new piece at the top of the board
    private static func spawnPiece(type: TetrominoType) -> ActivePiece {
        let startPos = type.startPosition
        return ActivePiece(type: type, x: startPos.x, y: startPos.y, rotation: 0)
    }
    
    /// Create a new piece and check for game over
    private func spawnNewPiece() -> ActivePiece {
        let newPiece = Self.spawnPiece(type: nextPieceType)
        nextPieceType = getNextPieceFromBag()

        // Check if new piece can be placed
        if board.isGameOver(newPiece) {
            gameOver()
        }

        pieceSpawnTime = Date()
        return newPiece
    }
    
    /// Lock the current piece and spawn a new one
    private func lockPieceAndSpawn() {
        board.lockPiece(currentPiece)

        // Clear any completed lines
        let cleared = board.clearLines()
        if cleared > 0 {
            updateScore(linesCleared: cleared)
        }

        // Award timing bonus based on how quickly the piece was placed
        if let spawnTime = pieceSpawnTime {
            let elapsed = Date().timeIntervalSince(spawnTime)
            let bonus: Int
            if elapsed < 2.0 {
                bonus = 50 * level
            } else if elapsed < 5.0 {
                bonus = 25 * level
            } else if elapsed < 10.0 {
                bonus = 10 * level
            } else {
                bonus = 0
            }
            score += bonus
        }

        // Spawn new piece
        currentPiece = spawnNewPiece()
    }
    
    // MARK: - Scoring
    
    /// Update score based on lines cleared
    private func updateScore(linesCleared: Int) {
        self.linesCleared += linesCleared
        
        // Classic Tetris scoring
        let lineScores = [0, 100, 300, 500, 800]
        score += lineScores[linesCleared] * level
        
        // Level up every 10 lines
        let newLevel = (self.linesCleared / 10) + 1
        if newLevel > level {
            level = newLevel
            updateTimerForLevel()
        }
    }
    
    // MARK: - Piece Movement
    
    /// Move the current piece left
    func movePieceLeft() {
        guard isGameRunning else { return }
        
        let movedPiece = currentPiece.moved(dx: -1, dy: 0)
        if board.canPlacePiece(movedPiece) {
            currentPiece = movedPiece
        }
    }
    
    /// Move the current piece right
    func movePieceRight() {
        guard isGameRunning else { return }
        
        let movedPiece = currentPiece.moved(dx: 1, dy: 0)
        if board.canPlacePiece(movedPiece) {
            currentPiece = movedPiece
        }
    }
    
    /// Move the current piece down (soft drop)
    /// Returns true if piece moved, false if it landed
    @discardableResult
    func movePieceDown() -> Bool {
        guard isGameRunning else { return false }
        
        let movedPiece = currentPiece.moved(dx: 0, dy: 1)
        
        if board.canPlacePiece(movedPiece) {
            currentPiece = movedPiece
            return true
        } else {
            // Piece has landed
            lockPieceAndSpawn()
            return false
        }
    }
    
    /// Hard drop - instantly drop the piece to the bottom
    func hardDrop() {
        guard isGameRunning else { return }
        
        // Move down until we can't
        while movePieceDown() {
            // Keep moving down
        }
        // Piece is automatically locked when movePieceDown returns false
    }
    
    /// Rotate the current piece clockwise
    func rotatePiece() {
        guard isGameRunning else { return }
        
        let rotatedPiece = currentPiece.rotated(clockwise: true)
        
        // Try the rotation
        if board.canPlacePiece(rotatedPiece) {
            currentPiece = rotatedPiece
            return
        }
        
        // Wall kick: try shifting left or right if rotation is blocked by wall
        let kicks = [-1, 1, -2, 2] // Try shifting left, right, then further
        for kick in kicks {
            let kickedPiece = rotatedPiece.moved(dx: kick, dy: 0)
            if board.canPlacePiece(kickedPiece) {
                currentPiece = kickedPiece
                return
            }
        }
    }
    
    // MARK: - UI Helpers
    
    /// Get the merged grid for rendering (includes current piece)
    func getDisplayGrid() -> [[Block]] {
        return board.getMergedGrid(with: currentPiece)
    }
    
    /// Get the block pattern for the next piece preview
    func getNextPieceBlocks() -> [[Bool]] {
        return nextPieceType.blocks(for: 0)
    }
    
    /// Get the color for the next piece
    var nextPieceColor: Color {
        return nextPieceType.color
    }
}
