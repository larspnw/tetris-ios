# Tetris for iOS

A SwiftUI Tetris game following the modern Tetris Guideline (SRS, 7-bag, hold, ghost,
lock delay, T-spin scoring), with Sprint/Ultra/Zen modes, a leaderboard, and an
inspirational-quotes feature.

## Architecture
- **`Engine/`** — pure-Swift game core (NO SwiftUI/UIKit imports). Deterministic and
  fully unit-testable on macOS. Time is driven by explicit `advance(dt:)` and randomness
  is injected, so the same inputs always produce the same result.
- **`Models/` `ViewModels/` `Views/` `Managers/`** — the SwiftUI app layer. The view
  model wraps the engine and drives it from a display timer; views render engine state.
- **`EngineTests/`** — XCTest unit tests for the engine (target ≥80% line coverage).
- **`Package.swift`** — SPM manifest so the engine + tests run via `swift test` without a
  simulator. The Xcode app target compiles the same `Engine/` files for iOS.

## Golden rules
- **Keep the engine SwiftUI-free.** Color/haptic/sound mapping lives in the app layer only.
- **Engine stays deterministic.** No `Date()`, no global RNG, no timers inside `Engine/`.
  Pass time deltas and an RNG in. This is what makes the tests fast and reliable.
- **Test-first for engine logic.** Rotations, kicks, scoring, and mode rules get a test
  before or alongside the implementation.
- **No regressions to existing interactions.** Before adding a gesture/handler, verify it
  doesn't break tap-to-rotate, swipe-to-move, etc.
- **Commit per logical change.** Bump `CFBundleVersion` via `scripts/increment-build.sh`
  (runs as a build phase) and keep the version visible on the menu screen.

## Build & test
```bash
# Engine unit tests + coverage (macOS, no simulator needed)
swift test --enable-code-coverage

# App build (needs an iOS simulator runtime installed)
xcodebuild -scheme Tetris -destination 'platform=iOS Simulator,name=iPhone 16' build

# Full test run incl. XCUITest E2E
xcodebuild test -scheme Tetris -destination 'platform=iOS Simulator,name=iPhone 16' \
  -enableCodeCoverage YES
```

## Tetris specifics (the rules the engine enforces)
- 10x40 internal matrix (20 visible + buffer rows above).
- SRS rotation with the JLSTZ and I wall-kick tables. Kick tables are stored in the
  standard y-UP convention and negated when applied to the y-DOWN board grid.
- 7-bag randomizer; hold (once per piece); ghost piece; hard drop; lock delay 0.5s with
  move-reset capped at 15.
- Scoring: 100/300/500/800 base (×level), T-spins, back-to-back ×1.5, combo, perfect clear,
  soft-drop 1/cell, hard-drop 2/cell. Gravity = (0.8 − (level−1)·0.007)^(level−1) sec/line.
- Modes: Sprint (40 lines, time = score), Ultra (120s score attack), Zen (endless, no top-out).

## Real-world caveat
"Tetris" and the Korobeiniki theme are trademarks of The Tetris Company. Fine for personal
use; a public App Store release would require an original name and original music.
