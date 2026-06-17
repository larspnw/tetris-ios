import SwiftUI

/// Per-mode leaderboard. Each entry shows its ranking metric and the date/time it was set.
struct LeaderboardView: View {
    @State private var mode: GameMode = .sprint
    private let leaderboard = LeaderboardService.shared

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 14) {
                Picker("Mode", selection: $mode) {
                    ForEach(GameMode.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                let entries = leaderboard.sorted(mode: mode)
                if entries.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "trophy").font(.largeTitle).foregroundColor(.gray)
                        Text("No scores yet").foregroundColor(.gray)
                        Text("Play \(mode.title) to set a record.").font(.caption).foregroundColor(.gray.opacity(0.7))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(Array(entries.enumerated()), id: \.offset) { idx, entry in
                                row(rank: idx + 1, entry: entry)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.top, 8)
        }
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(rank: Int, entry: LeaderboardEntry) -> some View {
        HStack(spacing: 14) {
            Text("#\(rank)").font(.headline).monospacedDigit().foregroundColor(rankColor(rank)).frame(width: 44, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(metric(entry)).font(.headline).foregroundColor(.white)
                Text(Self.dateFormatter.string(from: entry.date)).font(.caption).foregroundColor(.gray)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if !mode.ranksByTime { Text("\(entry.lines) lines").font(.caption).foregroundColor(.gray) }
                else { Text("\(entry.score) pts").font(.caption).foregroundColor(.gray) }
            }
        }
        .padding(.vertical, 10).padding(.horizontal, 14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.07)))
    }

    private func metric(_ entry: LeaderboardEntry) -> String {
        if mode.ranksByTime {
            let s = Int(entry.timeSeconds)
            return String(format: "%d:%02d", s / 60, s % 60)
        }
        return "\(entry.score)"
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank { case 1: return .yellow; case 2: return .gray; case 3: return .orange; default: return .white }
    }
}
