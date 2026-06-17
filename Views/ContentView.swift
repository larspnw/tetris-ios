import SwiftUI

/// The in-game screen for a chosen mode.
struct ContentView: View {
    let mode: GameMode
    @StateObject private var vm: GameViewModel
    @ObservedObject private var settings = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showSettings = false
    @State private var appliedCells = 0
    @State private var shake: CGFloat = 0

    init(mode: GameMode) {
        self.mode = mode
        _vm = StateObject(wrappedValue: GameViewModel(mode: mode))
    }

    private let tapThreshold: CGFloat = 12
    private let swipeThreshold: CGFloat = 24

    var body: some View {
        GeometryReader { geo in
            let cell = cellSize(for: geo.size)
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 10) {
                    topBar
                    statsRow
                    boardRow(cell: cell)
                    Spacer(minLength: 4)
                    controls
                }
                .padding(.vertical, 8)
                .offset(y: shake)
                .onChange(of: vm.impactToken) { _ in
                    let magnitude = 7 * vm.impactStrength
                    withAnimation(.interpolatingSpring(stiffness: 600, damping: 8)) { shake = magnitude }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                        withAnimation(.interpolatingSpring(stiffness: 400, damping: 12)) { shake = 0 }
                    }
                }

                if vm.engine.status == .paused { pauseOverlay }
                if vm.engine.status == .gameOver || vm.engine.status == .finished { endOverlay }
            }
        }
        .onAppear { vm.startGame() }
        .onDisappear { vm.cleanup() }
        .sheet(isPresented: $showSettings, onDismiss: { vm.resume() }) { SettingsView() }
    }

    // MARK: - Layout pieces

    private var topBar: some View {
        HStack {
            Button { vm.cleanup(); dismiss() } label: {
                Image(systemName: "chevron.left").font(.title2).foregroundColor(.white)
                    .padding(8).background(Circle().fill(Color.white.opacity(0.12)))
            }
            Spacer()
            Text(mode.title.uppercased()).font(.system(.title3, design: .rounded)).bold().foregroundColor(.white)
            Spacer()
            Button { vm.pause(); showSettings = true } label: {
                Image(systemName: "gearshape.fill").font(.title3).foregroundColor(.white).padding(8)
            }
            Button { vm.engine.status == .playing ? vm.pause() : vm.resume() } label: {
                Image(systemName: vm.engine.status == .playing ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2).foregroundColor(.white)
            }
            .accessibilityIdentifier("pauseToggle")
        }
        .padding(.horizontal)
    }

    private var statsRow: some View {
        HStack(spacing: 8) {
            StatChip(title: "SCORE", value: "\(vm.engine.score)")
            StatChip(title: "LEVEL", value: "\(vm.engine.level)")
            StatChip(title: "LINES", value: "\(vm.engine.lines)")
            StatChip(title: goalTitle, value: goalValue)
        }
        .padding(.horizontal)
    }

    private var goalTitle: String {
        switch mode {
        case .sprint: return "LEFT"
        case .ultra:  return "TIME"
        case .zen:    return "TIME"
        }
    }
    private var goalValue: String {
        switch mode {
        case .sprint: return "\(vm.engine.linesRemaining ?? 0)"
        case .ultra:  return timeString(vm.engine.timeRemaining ?? 0)
        case .zen:    return timeString(vm.engine.elapsedTime)
        }
    }

    private func boardRow(cell: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(spacing: 6) {
                Text("HOLD").font(.caption2).foregroundColor(.secondary)
                PiecePreview(kind: vm.engine.holdKind, cellSize: cell * 0.5, dimmed: true)
            }
            GameBoardView(grid: BoardRenderer.grid(vm.engine, ghostOn: settings.ghostEnabled),
                          cellSize: cell, clearProgress: vm.engine.clearProgress)
                .gesture(boardGesture(cell: cell))
            VStack(spacing: 6) {
                Text("NEXT").font(.caption2).foregroundColor(.secondary)
                ForEach(Array(vm.engine.nextQueue().prefix(5).enumerated()), id: \.offset) { _, k in
                    PiecePreview(kind: k, cellSize: cell * 0.42)
                }
            }
        }
        .padding(.horizontal, 6)
    }

    @ViewBuilder private var controls: some View {
        if vm.engine.status == .playing {
            if settings.controlScheme == .buttons {
                ControlPad(vm: vm).padding(.bottom, 8)
            } else {
                Text(settings.controlScheme == .drag
                     ? "Drag to move · tap to rotate · flick down to drop · swipe up to hold"
                     : "Swipe to move · tap to rotate · swipe down to drop · up to hold")
                    .font(.caption2).foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center).padding(.bottom, 8)
            }
        }
    }

    // MARK: - Gestures (swipe & drag schemes)

    private func boardGesture(cell: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard vm.engine.status == .playing else { return }
                // Cell-snapped horizontal movement.
                let target = Int((value.translation.width / cell).rounded(.towardZero))
                while appliedCells < target { vm.nudge(1); appliedCells += 1 }
                while appliedCells > target { vm.nudge(-1); appliedCells -= 1 }
                // Hold-to-soft-drop while dragging downward.
                if value.translation.height > cell, abs(value.translation.width) < cell {
                    vm.setSoftDrop(true)
                }
            }
            .onEnded { value in
                vm.setSoftDrop(false)
                defer { appliedCells = 0 }
                guard vm.engine.status == .playing else { return }
                let t = value.translation
                let p = value.predictedEndTranslation
                if abs(t.width) < tapThreshold, abs(t.height) < tapThreshold {
                    vm.rotate(clockwise: true)
                } else if t.height < -swipeThreshold, abs(t.height) > abs(t.width) {
                    vm.hold()
                } else if t.height > swipeThreshold, abs(t.height) > abs(t.width) {
                    if p.height > swipeThreshold * 4 { vm.hardDrop() } else { vm.setSoftDrop(false) }
                }
            }
    }

    // MARK: - Overlays

    private var pauseOverlay: some View {
        OverlayCard {
            Text("PAUSED").font(.largeTitle).bold().foregroundColor(.white)
            OverlayButton(title: "Resume", icon: "play.fill", color: .blue) { vm.resume() }
            OverlayButton(title: "Restart", icon: "arrow.clockwise", color: .orange) { vm.restart() }
            OverlayButton(title: "Menu", icon: "house.fill", color: .gray) { vm.cleanup(); dismiss() }
        }
    }

    private var endOverlay: some View {
        OverlayCard {
            Text(endTitle).font(.largeTitle).bold().foregroundColor(.white)
            VStack(spacing: 4) {
                Text("Score \(vm.engine.score)").font(.title3).foregroundColor(.white)
                if mode == .sprint, vm.engine.status == .finished {
                    Text("Time \(timeString(vm.engine.elapsedTime))").foregroundColor(.white.opacity(0.85))
                }
                Text("Lines \(vm.engine.lines)").font(.subheadline).foregroundColor(.white.opacity(0.7))
                if let rank = vm.lastRank {
                    Text("Leaderboard #\(rank)").font(.headline).foregroundColor(.yellow).padding(.top, 2)
                }
            }
            QuoteView(quote: vm.endQuote, compact: true).padding(.vertical, 4)
            OverlayButton(title: "Play Again", icon: "arrow.clockwise", color: .green) { vm.restart() }
            OverlayButton(title: "Menu", icon: "house.fill", color: .gray) { vm.cleanup(); dismiss() }
        }
    }

    private var endTitle: String {
        if vm.engine.status == .finished {
            return mode == .sprint ? "COMPLETE" : "TIME!"
        }
        return "GAME OVER"
    }

    // MARK: - Helpers

    private func cellSize(for size: CGSize) -> CGFloat {
        let sideColumns: CGFloat = 2 * (size.width * 0.16)
        let widthBudget = size.width - sideColumns - 24
        let byWidth = widthBudget / 10
        let byHeight = (size.height - 260) / 20
        return min(max(min(byWidth, byHeight), 12), 30)
    }

    private func timeString(_ t: TimeInterval) -> String {
        let s = Int(t)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

/// A centered translucent overlay card.
struct OverlayCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ZStack {
            Color.black.opacity(0.78).ignoresSafeArea()
            VStack(spacing: 16) { content }
                .padding(28)
                .frame(maxWidth: 340)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color(white: 0.1)))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1)))
                .padding(24)
        }
    }
}

struct OverlayButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack { Image(systemName: icon); Text(title) }
                .font(.headline).fontWeight(.semibold).foregroundColor(.white)
                .frame(maxWidth: 220).padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 12).fill(color))
        }
    }
}
