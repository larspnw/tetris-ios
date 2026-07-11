# Tetris for iOS

A modern-Guideline Tetris for iOS, built with SwiftUI on a pure-Swift, deterministic,
fully unit-tested game engine.

![Tetris Screenshot](screenshot.png)

## Features

- **Guideline core**: SRS rotation with full JLSTZ/I wall-kick tables, 7-bag randomizer,
  hold, ghost piece, 5-piece preview, hard/soft drop, 0.5s lock delay (15-move reset cap)
- **Scoring depth**: T-spins (full/mini, 3-corner rule), back-to-back ×1.5, combos,
  perfect clears, soft/hard-drop points, Tetris Worlds gravity curve
- **Flow**: a Zone-style meter — clearing lines charges it; activate to freeze gravity
  for 10 seconds while line clears bank at the bottom, then cash out all at once for an
  escalating bonus. A big-score play and a panic button in one.
- **Five modes**:
  - **Marathon** — clear 150 lines with rising speed; score is what counts
  - **Sprint** — clear 40 lines as fast as possible; time is your score
  - **Ultra** — 120-second score attack
  - **Zen** — endless, no game over, fixed relaxed gravity
  - **Classic** — NES rules: no hold, no ghost, one-piece preview, memoryless
    randomizer, NES frames-per-row gravity (killscreen at 29), 40/100/300/1200 scoring
- **Three control schemes**: swipe, drag, or on-screen buttons, with tunable DAS/ARR
- **Juice**: haptics, synthesized sound effects, line-clear flash/collapse, screen shake
- **Leaderboard**: per-mode top 25, persisted; **quotes** on launch and between games

## Requirements

- iOS 16.0+ / Xcode 15.0+ / Swift 5.9+

## How to run

Open `Tetris.xcodeproj` in Xcode, pick a simulator, `Cmd+R`.

## Testing

The engine is SwiftUI-free and deterministic (injected RNG, explicit time steps), so it
tests on macOS without a simulator:

```bash
swift test --enable-code-coverage   # engine unit tests
```

Full app build + XCUITest E2E (needs an iOS simulator runtime):

```bash
xcodebuild test -scheme Tetris -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Project structure

```
tetris-ios/
├── Engine/          # Pure-Swift game core (no SwiftUI/UIKit) — SRS, scoring, modes, Flow
├── EngineTests/     # XCTest suite for the engine (runs via `swift test`)
├── ViewModels/      # GameViewModel: display-link loop, DAS/ARR, event → juice mapping
├── Views/           # SwiftUI screens and board rendering
├── Managers/        # Settings, sound, haptics, leaderboard persistence
├── TetrisUITests/   # XCUITest end-to-end flows
└── Package.swift    # SPM manifest so the engine + tests run on macOS
```

See `CLAUDE.md` for engine rules and architecture guidance.

## Controls (swipe scheme)

| Gesture | Action |
|---------|--------|
| Tap | Rotate clockwise |
| Swipe left/right | Move |
| Drag down | Soft drop |
| Flick down | Hard drop |
| Swipe up | Hold |
| Flow bar (when full) | Activate Flow |

## Trademark note

"Tetris" and the Korobeiniki theme are trademarks of The Tetris Company. This project is
for personal use; a public App Store release would need an original name and music.

## License

Built for Lars. Feel free to modify and improve!
