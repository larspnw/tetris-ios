import SwiftUI

/// Pick a game mode: Sprint, Ultra, or Zen.
struct ModeSelectView: View {
    private let leaderboard = LeaderboardService.shared

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 18) {
                Text("Choose a Mode").font(.title).bold().foregroundColor(.white).padding(.top, 12)
                ForEach(GameMode.allCases, id: \.self) { mode in
                    NavigationLink(value: mode) { card(for: mode) }
                }
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Modes")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func card(for mode: GameMode) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon(mode)).font(.largeTitle).foregroundColor(color(mode)).frame(width: 52)
            VStack(alignment: .leading, spacing: 4) {
                Text(mode.title).font(.title2).bold().foregroundColor(.white)
                Text(mode.subtitle).font(.subheadline).foregroundColor(.gray)
                if let best = leaderboard.best(mode: mode) {
                    Text(bestText(mode, best)).font(.caption).foregroundColor(.yellow.opacity(0.85))
                }
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.gray)
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color(mode).opacity(0.5), lineWidth: 1))
    }

    private func bestText(_ mode: GameMode, _ e: LeaderboardEntry) -> String {
        if mode.ranksByTime {
            let s = Int(e.timeSeconds)
            return String(format: "Best: %d:%02d", s / 60, s % 60)
        }
        return "Best: \(e.score)"
    }

    private func icon(_ m: GameMode) -> String {
        switch m { case .sprint: return "flag.checkered"; case .ultra: return "timer"; case .zen: return "infinity" }
    }
    private func color(_ m: GameMode) -> Color {
        switch m { case .sprint: return .green; case .ultra: return .orange; case .zen: return .cyan }
    }
}
