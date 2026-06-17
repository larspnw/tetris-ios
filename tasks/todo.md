# Tetris Evolution Plan (Phases 0–5)

Goal: evolve the existing SwiftUI Tetris into a Guideline-correct, great-feeling game
with Sprint/Ultra/Zen modes, a leaderboard, and an inspirational-quotes feature.

## Decisions locked with Lars
- Build **Phases 0–5**.
- Modes: **Sprint (40 lines), Ultra (2-min score attack), Zen (endless, no top-out)**.
  (No Marathon, no versus/garbage.)
- **Keep scoring.** Leaderboard records **score + date/time** per run (nothing fancier).
- Show a **leaderboard** screen.
- **Quotes** on app launch and between games (game-over screen). Sources: Stoic
  philosophers (Marcus Aurelius, Seneca, Epictetus), Brad Stulberg, Naval Ravikant.

## Environment notes
- Xcode license: ACCEPTED (git/xcodebuild/swift all work).
- iOS Simulator *runtime* could not be downloaded (restricted network), so the app and
  XCUITest E2E cannot be *run* here. Everything still compiles/links:
  - Engine unit tests run on macOS via `swift test` (65 tests, 96% coverage).
  - App + UI-test target verified with `xcodebuild build` and `build-for-testing`
    (BUILD SUCCEEDED / TEST BUILD SUCCEEDED).
  - To run the app + E2E once a runtime is installed:
    `xcodebuild test -scheme Tetris -destination 'platform=iOS Simulator,name=iPhone 16'`

---

## Phase 0 — Hygiene + test scaffolding
- [ ] Replace wrong-project `CLAUDE.md` (currently "Wheel Strategy") with Tetris guidance.
- [ ] Add a **unit-test target** (XCTest); make the game engine SwiftUI-free so it's testable.
- [ ] Add a **UI-test target** (XCUITest) for end-to-end flows.
- [ ] Establish feature branch + commit-per-logical-change workflow.

## Phase 1 — Engine correctness (highest leverage)
- [ ] Refactor models: pure-Swift core (no SwiftUI `Color` in logic); color mapping in a view layer.
- [ ] Implement **SRS** rotation with JLSTZ + I wall-kick tables (negate y for screen-down grid).
- [ ] Add hidden **buffer rows** above the visible 20 (10x40 internal matrix).
- [ ] **Lock delay** (~0.5s) with move-reset, capped at 15 resets.
- [ ] **Ghost piece** (landing projection).
- [ ] **Hold** piece (once per piece until lock).
- [ ] **Hard drop** wired to a gesture (instant drop + lock).
- [ ] Expand next-queue preview to ~5 pieces.
- [ ] Fix `Board` change-notification so it composes with animations.

## Phase 2 — Scoring depth
- [ ] T-spin detection (3-corner rule + last-move-was-rotation; full vs mini; kick exception).
- [ ] Scoring table: T-spins, back-to-back (×1.5), combo, perfect clear.
- [ ] Soft-drop (1/cell) + hard-drop (2/cell) points.
- [ ] **Tetris Worlds gravity curve**: (0.8 − (level−1)*0.007)^(level−1).
- [ ] Retire the non-standard "timing bonus".

## Phase 3 — Juice
- [ ] Core Haptics: light (move/rotate), medium (lock), heavy (Tetris). prepare() to cut latency.
- [ ] Sound effects (move/rotate/lock/clear/tetris/level-up); optional music toggle.
- [ ] Line-clear animation (flash + collapse) and subtle screen shake / hit-pause on Tetris & hard drop.
- [ ] Wire all juice behind a settings toggle (haptics on/off, sound on/off).

## Phase 4 — Modes + Leaderboard + Quotes
- [ ] Mode selection screen: Sprint / Ultra / Zen.
- [ ] Sprint: clear 40 lines, timer is the score (lower = better).
- [ ] Ultra: 120-second countdown, maximize score.
- [ ] Zen: endless, no top-out (stack-out wraps/relaxes), relaxed gravity.
- [ ] Leaderboard store: per-mode entries of { score (or time), date/time }, persisted.
- [ ] Leaderboard screen with per-mode tabs, sorted appropriately.
- [ ] Quotes: curated list (Stoic / Stulberg / Naval); show on launch + between games.

## Phase 5 — Mobile controls
- [ ] Configurable control scheme in settings.
- [ ] Cell-snapped drag + ghost for one-handed casual play.
- [ ] Tunable DAS/ARR (auto-shift) for hold-to-slide.
- [ ] Distinct, hard-to-mis-trigger hard drop (decouple from sideways-move intent).
- [ ] Thumb-zone layout; never occlude the playfield; ≥44pt targets.

---

## Verification strategy
- **Unit tests (target: ≥80% line coverage on the engine).** XCTest over the SwiftUI-free core:
  - SRS rotation: every transition for JLSTZ + I against the canonical kick tables.
  - Wall kicks near walls/floor/overhangs; rotation rejection when all 5 tests fail.
  - 7-bag fairness (every 7 pieces contains all types; ≤12 between repeats).
  - Line clears (single..tetris), gravity collapse, board bounds/collision.
  - Scoring: base, T-spin (full/mini), back-to-back, combo, perfect clear, drop points.
  - Gravity curve values per level; lock-delay + 15-move-reset cap; hold-once-per-piece.
  - Mode rules: Sprint 40-line end, Ultra 120s end, Zen no top-out.
  - Leaderboard persistence (insert/sort/cap) and quote selection.
  - Measure with `xcodebuild test ... -enableCodeCoverage YES`; verify ≥80% via `xcrun xccov`.
- **E2E / UI tests (XCUITest), key flows:**
  - Launch → quote visible on menu → pick a mode → game starts.
  - Play a few inputs (rotate/move/hard-drop) → pause → resume → quit to menu.
  - Game over → quote shown → score written → appears on leaderboard.
  - Settings toggle (haptics/sound/controls) persists across relaunch.
- App build: `xcodebuild -scheme Tetris -destination 'platform=iOS Simulator,name=iPhone 16'`.
- Per-phase: bump CFBundleVersion (existing increment-build.sh), commit with a clear message.

## Real-world caveat
- "Tetris" + Korobeiniki are trademarks of The Tetris Company. Fine for personal use;
  a public App Store release would need an original name + original music.

## Review log
- **Phase 0 (DONE):** Replaced wrong-project CLAUDE.md. Added SPM manifest + XCTest engine
  suite and an XCUITest target with a shared scheme.
- **Phase 1 (DONE):** SwiftUI-free engine — SRS + full kick tables, 10x40 buffer, lock delay
  (0.5s / 15-reset cap), ghost, hold, hard drop, 5-piece preview. App rewired to the engine.
- **Phase 2 (DONE):** T-spins, back-to-back, combo, perfect clear, soft/hard-drop points,
  Tetris Worlds gravity curve. Old timing-bonus removed.
- **Phase 3 (DONE):** Haptics (prepare()'d), synthesized sound effects, screen shake on
  hard drop / Tetris. (Background music intentionally omitted — trademark on Korobeiniki.)
- **Phase 4 (DONE):** Sprint/Ultra/Zen modes, mode-select screen, leaderboard (score/time +
  date, per-mode tabs, capped & persisted), quotes on launch + between games.
- **Phase 5 (DONE):** Configurable controls (Swipe/Drag/Buttons), tunable DAS/ARR, distinct
  hard-drop gesture, thumb-zone on-screen pad, ≥44pt targets.
- **Tests:** 65 engine unit tests passing, 96.0% line coverage (target was 80%). XCUITest
  E2E written + compiling; needs a simulator runtime to execute.
- **Remaining / nice-to-have:** richer line-clear animation (currently shake + haptic only);
  run the E2E suite once a runtime is available; optional Xcode unit-test target mirroring
  the SPM tests (engine coverage already met via `swift test`).
