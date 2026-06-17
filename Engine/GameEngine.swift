import Foundation

public enum GameStatus: Equatable, Sendable {
    case ready
    case playing
    case paused
    case gameOver    // topped out
    case finished    // mode goal reached (Sprint cleared 40 / Ultra time up)
}

/// The deterministic Tetris game core. Drive it with `advance(dt:)` and the input methods.
/// Contains no timers, `Date()`, or global RNG so it can be unit-tested exactly.
public final class GameEngine {

    // Tuning constants.
    public static let lockDelay: TimeInterval = 0.5
    public static let maxLockResets = 15
    private static let softDropCellInterval: TimeInterval = 1.0 / 30.0

    // Configuration.
    public let mode: GameMode
    public let previewCount: Int

    // Observable-ish state (the app layer reads these each frame).
    public private(set) var field: Playfield
    public private(set) var current: Piece
    public private(set) var holdKind: TetrominoKind?
    public private(set) var status: GameStatus = .ready
    public private(set) var score = 0
    public private(set) var lines = 0
    public private(set) var level = 1
    public private(set) var elapsedTime: TimeInterval = 0
    public private(set) var lastOutcome: ClearOutcome = .zero
    public private(set) var piecesPlaced = 0

    /// True when the current piece is resting on the stack/floor (lock delay is counting).
    public var isOnGround: Bool { field.collides(current.moved(dx: 0, dy: 1)) }

    // Internals.
    private var bag: SevenBag
    private var scorer = Scorer()
    private var canHold = true
    private var softDropping = false
    private var fallAccumulator: TimeInterval = 0
    private var lockTimer: TimeInterval = 0
    private var lockResets = 0
    private var lastActionWasRotation = false
    private var usedLongKick = false

    public init(mode: GameMode,
                previewCount: Int = 5,
                rng: any RandomNumberGenerator = SystemRandomNumberGenerator()) {
        self.mode = mode
        self.previewCount = previewCount
        self.field = Playfield()
        self.bag = SevenBag(rng: rng)
        // Temporary; replaced in start().
        self.current = Piece(kind: .i, origin: Coord(0, 0))
    }

    // MARK: - Derived state for the UI

    /// The next `previewCount` upcoming pieces.
    public func nextQueue() -> [TetrominoKind] { bag.preview(previewCount) }

    /// The ghost (landing projection) of the current piece.
    public var ghost: Piece { field.ghost(current) }

    /// Remaining time for Ultra (seconds), or nil for other modes.
    public var timeRemaining: TimeInterval? {
        mode == .ultra ? max(0, GameMode.ultraDuration - elapsedTime) : nil
    }

    /// Lines left to clear for Sprint, or nil otherwise.
    public var linesRemaining: Int? {
        mode == .sprint ? max(0, GameMode.sprintLineGoal - lines) : nil
    }

    /// Spawn origin for a kind: horizontally centered, at the top of the visible field.
    private func spawnOrigin(for kind: TetrominoKind) -> Coord {
        let box = TetrominoShapes.boxSize(kind)
        let x = (field.width - box) / 2
        return Coord(x, field.bufferHeight - 2)
    }

    // MARK: - Lifecycle

    public func start() {
        field.reset()
        scorer.reset()
        score = 0; lines = 0; level = 1; elapsedTime = 0; piecesPlaced = 0
        holdKind = nil; canHold = true; softDropping = false
        fallAccumulator = 0; lockTimer = 0; lockResets = 0
        lastActionWasRotation = false; usedLongKick = false
        lastOutcome = .zero
        status = .playing
        spawnNext()
    }

    public func pause()  { if status == .playing { status = .paused } }
    public func resume() { if status == .paused  { status = .playing } }

    private func spawn(kind: TetrominoKind) {
        current = Piece(kind: kind, state: .spawn, origin: spawnOrigin(for: kind))
        lockTimer = 0; lockResets = 0; fallAccumulator = 0
        lastActionWasRotation = false; usedLongKick = false
        if field.collides(current) { topOut() }
    }

    private func spawnNext() { spawn(kind: bag.next()) }

    private func topOut() {
        if mode == .zen {
            field.reset()   // Zen never ends; clear the stack and keep going.
        } else {
            status = .gameOver
        }
    }

    // MARK: - Time

    public func advance(dt: TimeInterval) {
        guard status == .playing else { return }
        elapsedTime += dt

        if mode == .ultra && elapsedTime >= GameMode.ultraDuration {
            elapsedTime = GameMode.ultraDuration
            status = .finished
            return
        }

        let grounded = field.collides(current.moved(dx: 0, dy: 1))
        if grounded {
            lockTimer += dt
            if lockTimer >= Self.lockDelay { lockCurrentPiece() }
        } else {
            lockTimer = 0
            lockResets = 0
            fallAccumulator += dt
            let interval = currentFallInterval()
            while fallAccumulator >= interval && !field.collides(current.moved(dx: 0, dy: 1)) {
                fallAccumulator -= interval
                current = current.moved(dx: 0, dy: 1)
                lastActionWasRotation = false
                if softDropping { score += 1 }
            }
        }
    }

    private func currentFallInterval() -> TimeInterval {
        let gravity = Gravity.secondsPerLine(level: level)
        return softDropping ? min(gravity, Self.softDropCellInterval) : gravity
    }

    // MARK: - Inputs

    /// Move the current piece down one cell if possible, awarding 1 soft-drop point.
    /// Useful for discrete (swipe/tap) soft drops. Returns whether it moved.
    @discardableResult
    public func softDropStep() -> Bool {
        guard status == .playing else { return false }
        let cand = current.moved(dx: 0, dy: 1)
        guard !field.collides(cand) else { return false }
        current = cand
        score += 1
        lastActionWasRotation = false
        return true
    }

    public func setSoftDrop(_ on: Bool) {
        guard status == .playing else { return }
        softDropping = on
        if on { fallAccumulator = currentFallInterval() } // first step is immediate
    }

    @discardableResult
    public func moveLeft() -> Bool { move(dx: -1) }
    @discardableResult
    public func moveRight() -> Bool { move(dx: 1) }

    private func move(dx: Int) -> Bool {
        guard status == .playing else { return false }
        let cand = current.moved(dx: dx, dy: 0)
        guard !field.collides(cand) else { return false }
        current = cand
        lastActionWasRotation = false
        registerLockReset()
        return true
    }

    @discardableResult
    public func rotate(clockwise: Bool) -> Bool {
        guard status == .playing else { return false }
        let from = current.state
        let to = from.rotated(clockwise: clockwise)
        let offsets = SRSKicks.offsets(kind: current.kind, from: from, to: to)
        for (i, off) in offsets.enumerated() {
            // Kick tables are y-up; negate y for the y-down board.
            let cand = current.withState(to).moved(dx: off.x, dy: -off.y)
            if !field.collides(cand) {
                current = cand
                lastActionWasRotation = true
                usedLongKick = (i == 4)
                registerLockReset()
                return true
            }
        }
        return false
    }

    private func registerLockReset() {
        guard field.collides(current.moved(dx: 0, dy: 1)) else { return } // only when grounded
        guard lockResets < Self.maxLockResets else { return }
        lockTimer = 0
        lockResets += 1
    }

    public func hardDrop() {
        guard status == .playing else { return }
        let d = field.dropDistance(current)
        if d > 0 {
            current = current.moved(dx: 0, dy: d)
            score += 2 * d
            lastActionWasRotation = false
        }
        lockCurrentPiece()
    }

    public func hold() {
        guard status == .playing, canHold else { return }
        canHold = false
        let outgoing = current.kind
        if let h = holdKind {
            holdKind = outgoing
            spawn(kind: h)
        } else {
            holdKind = outgoing
            spawnNext()
        }
    }

    // MARK: - Locking & clearing

    private func lockCurrentPiece() {
        // Classify a T-spin from the resting position before locking.
        let tspin = TSpinDetector.detect(piece: current,
                                          field: field,
                                          lastActionWasRotation: lastActionWasRotation,
                                          usedLongKick: usedLongKick)
        field.lock(current)
        let cleared = field.clearFullLines().count
        let perfect = (cleared > 0) && field.isEmpty

        if cleared > 0 || tspin != .none {
            let outcome = scorer.register(lines: cleared, tspin: tspin, level: level, perfectClear: perfect)
            score += outcome.points
            lastOutcome = outcome
        } else {
            lastOutcome = .zero
            _ = scorer.register(lines: 0, tspin: .none, level: level, perfectClear: false) // resets combo
        }

        lines += cleared
        level = lines / 10 + 1
        piecesPlaced += 1

        // Mode completion check (Sprint).
        if mode == .sprint && lines >= GameMode.sprintLineGoal {
            status = .finished
            return
        }

        canHold = true
        spawnNext()
    }
}
