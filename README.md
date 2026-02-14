# Tetris for iOS

A complete Tetris implementation for iOS built with SwiftUI.

![Tetris Screenshot](screenshot.png)

## Features

- **Classic Tetris Gameplay**: All 7 standard tetrominoes (I, O, T, S, Z, J, L)
- **10x20 Game Board**: Standard Tetris dimensions
- **Touch Controls**:
  - Tap to rotate piece
  - Swipe left/right to move
  - Swipe down for soft drop
- **Progressive Difficulty**: Speed increases as you level up
- **Scoring System**: Classic Tetris scoring (100/300/500/800 points per 1-4 lines)
- **Level System**: Level up every 10 lines cleared
- **Next Piece Preview**: See what's coming next
- **Pause/Resume**: Take breaks anytime
- **Game Over Detection**: Automatic restart option

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

## How to Run

### Option 1: Open in Xcode

1. Open `Tetris.xcodeproj` in Xcode
2. Select your target device or simulator
3. Press `Cmd+R` to build and run

### Option 2: Swift Package Manager

```bash
cd /Users/larry/Projects/tetris-ios
swift build
```

## Project Structure

```
tetris-ios/
├── TetrisApp.swift              # App entry point
├── Tetris.xcodeproj/            # Xcode project
├── Info.plist                   # App configuration
│
├── Models/                      # Data models
│   ├── TetrominoType.swift     # Piece definitions and rotations
│   ├── GameModels.swift        # Block, ActivePiece, GameState
│   └── Board.swift             # Game board grid logic
│
├── ViewModels/                  # Business logic
│   └── GameViewModel.swift     # Game state management & rules
│
└── Views/                       # UI components
    ├── ContentView.swift       # Main game view
    └── GameComponents.swift    # Board, blocks, overlays
```

## Game Controls

| Gesture | Action |
|---------|--------|
| Tap | Rotate piece clockwise |
| Swipe Left | Move piece left |
| Swipe Right | Move piece right |
| Swipe Down | Soft drop (move down faster) |
| Pause Button | Pause/Resume game |

## Scoring

- 1 line: 100 × level
- 2 lines: 300 × level
- 3 lines: 500 × level
- 4 lines (Tetris): 800 × level

## Level Progression

- Start at Level 1
- Level increases every 10 lines cleared
- Fall speed increases with each level

## Code Highlights

### Tetromino Rotation System
Each piece type has 4 rotation states (0°, 90°, 180°, 270°). The rotation system uses wall kicks to allow pieces to rotate near walls.

### 7-Bag Randomizer
Pieces are drawn from a bag containing all 7 tetrominoes, ensuring fair distribution and preventing long runs without a specific piece.

### Collision Detection
The board validates all piece movements before applying them, checking both boundary conditions and collision with locked pieces.

## Known Limitations

1. **No Hold Feature**: Classic Tetris hold piece not implemented
2. **No Ghost Piece**: No preview of where piece will land
3. **Limited Wall Kicks**: Basic wall kick system (SRS not fully implemented)
4. **No High Score Persistence**: Scores reset when app closes
5. **No Sound**: No audio effects or music

## Future Improvements

- [ ] Add hold piece functionality (swap current piece)
- [ ] Add ghost piece preview
- [ ] Implement Super Rotation System (SRS)
- [ ] Add high score persistence with UserDefaults
- [ ] Add sound effects and background music
- [ ] Add haptic feedback for piece landing
- [ ] Add hard drop (instant drop to bottom)
- [ ] Add combo scoring multipliers
- [ ] Add T-spin detection and scoring
- [ ] Add settings menu for speed/controls
- [ ] Add dark/light theme toggle

## License

Built for Lars. Feel free to modify and improve!
