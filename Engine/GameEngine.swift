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

    // Flow tuning: the meter fills after `flowChargeToReady` cleared lines; activating
    // freezes gravity for `flowDuration` while full rows are banked instead of cleared.
    public static let flowDuration: TimeInterval = 10
    public static let flowChargeToReady = 12

    // Configuration.
    public let mode: GameMode
    public let previewCount: Int
    /// Pause (seconds) after a line clear during which full rows are shown before they
    /// collapse. Default 0 keeps clears instantaneous; the app sets a small value to animate.
    public var lineClearDelay: TimeInterval = 0

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

    // Flow (zone-style) state.
    /// Cleared lines banked toward the next Flow (integer so the meter fills exactly,
    /// free of the float-accumulation drift that could leave it at 0.999… forever).
    public private(set) var flowChargeLines = 0
    public private(set) var flowActive = false
    public private(set) var flowTimeRemaining: TimeInterval = 0
    public private(set) var flowLines = 0                     // lines banked this Flow
    public private(set) var lastFlowBonus = 0                 // points from the last cash-out
    public private(set) var flowEndCount = 0                  // bumped per cash-out (UI event edge)

    /// Meter fill, 0...1.
    public var flowCharge: Double {
        min(1, Double(flowChargeLines) / Double(Self.flowChargeToReady))
    }
    /// The meter is full and Flow can be activated right now.
    public var flowReady: Bool {
        mode.flowEnabled && !flowActive && flowChargeLines >= Self.flowChargeToReady && status == .playing
    }

    /// Rows currently flashing before they collapse (empty unless mid line-clear animation).
    public private(set) var clearingRows: [Int] = []
    public var isClearing: Bool { !clearingRows.isEmpty }
    /// Progress of the line-clear animation, 0...1.
    public var clearProgress: Double {
        isClearing ? min(1, clearTimer / max(0.0001, lineClearDelay)) : 0
    }
    private var clearTimer: TimeInterval = 0

    // Internals.
    private var bag: any PieceRandomizer
    private var scorer = Scorer()
    private var canHold = true
    private var softDropping = false
    private var fallAccumulator: TimeInterval = 0
    private var lockTimer: TimeInterval = 0
    private var lockResets = 0
    private var lastActionWasRotation = false
    private var usedLongKick = false

    public init(mode: GameMode,
                previewCount: Int? = nil,
                rng: any RandomNumberGenerator = SystemRandomNumberGenerator()) {
        self.mode = mode
        self.previewCount = previewCount ?? mode.defaultPreviewCount
        self.field = Playfield()
        self.bag = mode.usesSevenBag ? SevenBag(rng: rng) : ClassicRandomizer(rng: rng)
        // Temporary; replaced in start().
        self.current = Piece(kind: .i, origin: Coord(0, 0))
    }

    // MARK: - Derived state for the UI

    /// The next `previewCount` upcoming pieces.
    public func nextQueue() -> [TetrominoKind] { bag.preview(previewCount) }

    /// The ghost (landing projection) of the current piece.
    public var ghost: Piece { field.ghost(current) }

    /// Remaining time for a time-limited mode (Ultra), or nil otherwise.
    public var timeRemaining: TimeInterval? {
        mode.duration.map { max(0, $0 - elapsedTime) }
    }

    /// Lines left to clear for a line-goal mode (Sprint/Marathon), or nil otherwise.
    public var linesRemaining: Int? {
        mode.lineGoal.map { max(0, $0 - lines) }
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
        clearingRows = []; clearTimer = 0
        flowChargeLines = 0; flowActive = false; flowTimeRemaining = 0
        flowLines = 0; lastFlowBonus = 0; flowEndCount = 0
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

        if let limit = mode.duration, elapsedTime >= limit {
            elapsedTime = limit
            if flowActive { endFlow() }   // cash out the banked lines before the buzzer
            status = .finished
            return
        }

        // While a line clear is animating, the board is frozen until the delay elapses.
        if isClearing {
            clearTimer += dt
            if clearTimer >= lineClearDelay { finalizeClear() }
            return
        }

        if flowActive {
            flowTimeRemaining -= dt
            if flowTimeRemaining <= 0 {
                endFlow()
                if checkLineGoal() { return }
            }
        }

        let grounded = field.collides(current.moved(dx: 0, dy: 1))
        if grounded {
            lockTimer += dt
            if lockTimer >= effectiveLockDelay { lockCurrentPiece() }
        } else {
            lockTimer = 0
            lockResets = 0
            // During Flow, automatic gravity is frozen — but the player can still soft-drop
            // to place pieces into the bank. Only skip the fall loop when it would be pure
            // gravity (nothing to do), so a held soft drop keeps working.
            guard !flowActive || softDropping else { return }
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
        let gravity: TimeInterval
        switch mode {
        case .zen:     gravity = Gravity.zenSecondsPerLine
        case .classic: gravity = Gravity.nesSecondsPerRow(nesLevel: level - 1)
        default:       gravity = Gravity.secondsPerLine(level: level)
        }
        return softDropping ? min(gravity, Self.softDropCellInterval) : gravity
    }

    /// Classic gets no modern lock delay — just the current gravity step to slide,
    /// NES-style. Modern modes use the Guideline 0.5s.
    private var effectiveLockDelay: TimeInterval {
        mode == .classic ? currentFallInterval() : Self.lockDelay
    }

    // MARK: - Inputs

    /// Move the current piece down one cell if possible, awarding 1 soft-drop point.
    /// Useful for discrete (swipe/tap) soft drops. Returns whether it moved.
    @discardableResult
    public func softDropStep() -> Bool {
        guard status == .playing, !isClearing else { return false }
        let cand = current.moved(dx: 0, dy: 1)
        guard !field.collides(cand) else { return false }
        current = cand
        score += 1
        lastActionWasRotation = false
        return true
    }

    public func setSoftDrop(_ on: Bool) {
        guard status == .playing, !isClearing else { return }
        softDropping = on
        if on { fallAccumulator = currentFallInterval() } // first step is immediate
    }

    @discardableResult
    public func moveLeft() -> Bool { move(dx: -1) }
    @discardableResult
    public func moveRight() -> Bool { move(dx: 1) }

    private func move(dx: Int) -> Bool {
        guard status == .playing, !isClearing else { return false }
        let cand = current.moved(dx: dx, dy: 0)
        guard !field.collides(cand) else { return false }
        current = cand
        lastActionWasRotation = false
        registerLockReset()
        return true
    }

    @discardableResult
    public func rotate(clockwise: Bool) -> Bool {
        guard status == .playing, !isClearing else { return false }
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
        guard mode != .classic else { return }                            // NES: no mercy
        guard field.collides(current.moved(dx: 0, dy: 1)) else { return } // only when grounded
        guard lockResets < Self.maxLockResets else { return }
        lockTimer = 0
        lockResets += 1
    }

    public func hardDrop() {
        guard status == .playing, !isClearing else { return }
        let d = field.dropDistance(current)
        if d > 0 {
            current = current.moved(dx: 0, dy: d)
            score += 2 * d
            lastActionWasRotation = false
        }
        lockCurrentPiece()
    }

    /// Enter Flow: gravity freezes and full rows are banked at the bottom of the field,
    /// clearing all at once (with an escalating bonus) when the Flow ends. Returns whether
    /// it actually started, so the app layer only plays activation feedback on success.
    @discardableResult
    public func activateFlow() -> Bool {
        guard flowReady, !isClearing else { return false }
        flowActive = true
        flowChargeLines = 0
        flowLines = 0
        flowTimeRemaining = Self.flowDuration
        return true
    }

    /// Cash out the banked rows, award the bonus, and count the lines.
    private func endFlow() {
        flowActive = false
        flowTimeRemaining = 0
        if flowLines > 0 {
            field.clearFullLines()   // the only full rows are the banked ones
            lastFlowBonus = Scorer.flowBonus(lines: flowLines, level: level)
            score += lastFlowBonus
            lines += flowLines
            recomputeLevel()
        } else {
            lastFlowBonus = 0
        }
        flowLines = 0                // banked rows are gone; don't re-credit them later
        flowEndCount += 1
    }

    private func chargeFlow(lines n: Int) {
        guard mode.flowEnabled, !flowActive else { return }
        flowChargeLines = min(Self.flowChargeToReady, flowChargeLines + n)
    }

    /// Whether `kind` can spawn at its origin without colliding.
    private func canSpawn(_ kind: TetrominoKind) -> Bool {
        !field.collides(Piece(kind: kind, state: .spawn, origin: spawnOrigin(for: kind)))
    }

    /// Spawn `kind`, but if an active Flow would otherwise top out on spawn, cash the
    /// bank out first (clearing it usually frees the space). Used by the Flow lock path
    /// and by hold() so neither can strand or lose a live bank.
    private func flowSafeSpawn(kind: TetrominoKind) {
        if flowActive, !canSpawn(kind) {
            endFlow()
            if checkLineGoal() { return }   // run finished on the cash-out
        }
        spawn(kind: kind)
    }

    /// Flow variant of the lock step: bank new full rows at the bottom instead of
    /// scoring/clearing them, then bring in the next piece.
    private func lockDuringFlow() {
        // Banked rows sit full at the very bottom; any full row above them is new.
        let newFull = field.fullRows().filter { $0 < field.totalHeight - flowLines }
        if !newFull.isEmpty {
            field.sinkRows(newFull)
            flowLines += newFull.count
        }
        lastOutcome = .zero
        piecesPlaced += 1
        canHold = true
        flowSafeSpawn(kind: bag.next())
    }

    public func hold() {
        guard status == .playing, canHold, mode.holdEnabled, !isClearing else { return }
        canHold = false
        let outgoing = current.kind
        if let h = holdKind {
            holdKind = outgoing
            flowSafeSpawn(kind: h)   // flow-safe: cashes out rather than topping out
        } else {
            holdKind = outgoing
            flowSafeSpawn(kind: bag.next())
        }
    }

    // MARK: - Locking & clearing

    private func lockCurrentPiece() {
        // Classify a T-spin from the resting position before locking (Guideline only).
        let tspin: TSpin = mode.scoringStyle == .guideline
            ? TSpinDetector.detect(piece: current,
                                   field: field,
                                   lastActionWasRotation: lastActionWasRotation,
                                   usedLongKick: usedLongKick)
            : .none
        field.lock(current)

        if flowActive {
            lockDuringFlow()
            return
        }

        let full = field.fullRows()
        let cleared = full.count
        // Would the field be empty once these rows are removed? (perfect clear)
        let perfect = (cleared > 0) && (field.filledCount == cleared * field.width)

        switch mode.scoringStyle {
        case .guideline:
            if cleared > 0 || tspin != .none {
                let outcome = scorer.register(lines: cleared, tspin: tspin, level: level, perfectClear: perfect)
                score += outcome.points
                lastOutcome = outcome
            } else {
                lastOutcome = .zero
                _ = scorer.register(lines: 0, tspin: .none, level: level, perfectClear: false) // resets combo
            }
        case .nes:
            let points = Scorer.nesPoints(lines: cleared, level: level)
            score += points
            lastOutcome = cleared > 0
                ? ClearOutcome(linesCleared: cleared, tspin: .none, perfectClear: false,
                               backToBack: false, combo: -1, points: points)
                : .zero
        }

        lines += cleared
        recomputeLevel()
        piecesPlaced += 1
        if cleared > 0 { chargeFlow(lines: cleared) }

        // Mode completion check (Sprint/Marathon): finish immediately, removing the rows.
        if checkLineGoal() { return }

        if lineClearDelay > 0 && cleared > 0 {
            // Defer the collapse + next spawn so the UI can animate the full rows.
            clearingRows = full
            clearTimer = 0
        } else {
            if cleared > 0 { field.clearFullLines() }
            canHold = true
            spawnNext()
        }
    }

    /// Finish the run if the mode's line goal has been reached. Returns true if it ended.
    private func checkLineGoal() -> Bool {
        guard let goal = mode.lineGoal, lines >= goal else { return false }
        field.clearFullLines()
        status = .finished
        return true
    }

    /// Recompute the level from the cleared-line count (10 lines per level). One place so
    /// normal locks and Flow cash-outs can never disagree on the curve.
    private func recomputeLevel() { level = lines / 10 + 1 }

    #if DEBUG
    /// Test hook: load a specific board state (not part of the shipping API).
    func _testLoadField(_ f: Playfield) { field = f }
    /// Test hook: pretend `n` lines have already been cleared (recomputes the level).
    func _testSetLines(_ n: Int) { lines = n; recomputeLevel() }
    /// Test hook: fill the Flow meter without grinding 12 line clears.
    func _testFillFlowCharge() { flowChargeLines = Self.flowChargeToReady }
    #endif

    /// Remove the flashed rows and bring in the next piece (end of the clear animation).
    private func finalizeClear() {
        field.clearFullLines()
        clearingRows = []
        clearTimer = 0
        canHold = true
        spawnNext()
    }
}
