import SwiftUI
import QuartzCore

/// Drives the deterministic `GameEngine` from a display link, publishes a redraw signal,
/// fires haptics/sound on game events, applies DAS/ARR auto-repeat, and records finished
/// runs to the leaderboard.
final class GameViewModel: NSObject, ObservableObject {
    let engine: GameEngine
    let mode: GameMode

    /// Bumped every frame so SwiftUI re-reads the engine state.
    @Published private(set) var frame: UInt64 = 0
    /// Quote shown on the game-over / finished overlay (between games).
    @Published private(set) var endQuote: Quote = QuoteBook.random()
    /// Rank of the just-finished run within its mode, if it was recorded.
    @Published private(set) var lastRank: Int?
    /// Bumped to trigger a screen-shake; `impactStrength` carries its magnitude (0...1).
    @Published private(set) var impactToken = 0
    private(set) var impactStrength: CGFloat = 0

    private let settings = SettingsManager.shared
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0

    // Event-edge tracking.
    private var seenPieces = 0
    private var seenLevel = 1
    private var resultRecorded = false

    // DAS/ARR auto-repeat for held horizontal movement.
    private var moveDir = 0
    private var dasElapsed = 0.0
    private var arrElapsed = 0.0
    private var dasCharged = false

    init(mode: GameMode) {
        self.mode = mode
        self.engine = GameEngine(mode: mode)
        super.init()
    }

    // MARK: - Lifecycle

    func startGame() {
        Haptics.shared.prepare()
        SoundManager.shared.start()
        engine.start()
        seenPieces = engine.piecesPlaced
        seenLevel = engine.level
        resultRecorded = false
        moveDir = 0
        startLoop()
    }

    func pause() { engine.pause(); stopLoop(); frame &+= 1 }
    func resume() { guard engine.status == .paused else { return }; engine.resume(); startLoop(); frame &+= 1 }

    func cleanup() { stopLoop() }

    private func startLoop() {
        stopLoop()
        lastTimestamp = 0
        let link = CADisplayLink(target: self, selector: #selector(step(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopLoop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func step(_ link: CADisplayLink) {
        let now = link.timestamp
        if lastTimestamp == 0 { lastTimestamp = now; return }
        let dt = min(now - lastTimestamp, 1.0 / 20.0) // clamp to avoid huge jumps
        lastTimestamp = now

        updateAutoShift(dt: dt)
        engine.advance(dt: dt)
        processEvents()
        frame &+= 1

        if engine.status == .gameOver || engine.status == .finished {
            finishRun()
        }
    }

    // MARK: - Events → juice

    private func processEvents() {
        if engine.piecesPlaced > seenPieces {
            seenPieces = engine.piecesPlaced
            let outcome = engine.lastOutcome
            if outcome.tspin != .none { Haptics.shared.tspin(); SoundManager.shared.tspin() }
            if outcome.linesCleared > 0 {
                Haptics.shared.lineClear(outcome.linesCleared)
                SoundManager.shared.lineClear(outcome.linesCleared)
                impact(outcome.linesCleared >= 4 ? 1.0 : 0.4)
            } else {
                Haptics.shared.lock(); SoundManager.shared.lock()
            }
        }
        if engine.level > seenLevel {
            seenLevel = engine.level
            Haptics.shared.levelUp(); SoundManager.shared.levelUp()
        }
    }

    private func finishRun() {
        guard !resultRecorded else { return }
        resultRecorded = true
        stopLoop()
        Haptics.shared.gameOver()
        SoundManager.shared.gameOver()
        endQuote = QuoteBook.random()

        // Zen never reaches this branch (it never ends). Record Sprint/Ultra runs.
        let entry = LeaderboardEntry(mode: mode,
                                     score: engine.score,
                                     lines: engine.lines,
                                     timeSeconds: engine.elapsedTime,
                                     date: Date())
        // Sprint only counts as a result if the 40-line goal was reached (status .finished).
        if mode == .sprint && engine.status != .finished {
            lastRank = nil
        } else {
            lastRank = LeaderboardService.shared.record(entry)
        }
    }

    // MARK: - Inputs

    func moveLeftPressed()  { beginMove(-1) }
    func moveRightPressed() { beginMove(1) }
    func horizontalReleased() { moveDir = 0; dasCharged = false }

    private func beginMove(_ dir: Int) {
        moveDir = dir
        dasElapsed = 0; arrElapsed = 0; dasCharged = false
        performMove(dir)
    }

    /// Discrete single move (for the swipe scheme).
    func nudge(_ dir: Int) { performMove(dir) }

    private func performMove(_ dir: Int) {
        let moved = dir < 0 ? engine.moveLeft() : engine.moveRight()
        if moved { Haptics.shared.move(); SoundManager.shared.move() }
    }

    private func updateAutoShift(dt: Double) {
        guard moveDir != 0, engine.status == .playing else { return }
        if !dasCharged {
            dasElapsed += dt
            if dasElapsed * 1000 >= settings.dasMilliseconds { dasCharged = true; arrElapsed = 0 }
        } else {
            arrElapsed += dt
            let arr = max(0.001, settings.arrMilliseconds / 1000)
            while arrElapsed >= arr { arrElapsed -= arr; performMove(moveDir) }
        }
    }

    func rotate(clockwise: Bool) {
        if engine.rotate(clockwise: clockwise) { Haptics.shared.rotate(); SoundManager.shared.rotate() }
    }

    private func impact(_ strength: CGFloat) {
        impactStrength = strength
        impactToken &+= 1
    }

    func hardDrop() {
        Haptics.shared.hardDrop(); SoundManager.shared.hardDrop()
        impact(0.5)
        engine.hardDrop()
        processEvents()
        frame &+= 1
        if engine.status == .gameOver || engine.status == .finished { finishRun() }
    }

    func setSoftDrop(_ on: Bool) { engine.setSoftDrop(on) }

    func hold() { engine.hold(); frame &+= 1 }

    func restart() { startGame() }
}
