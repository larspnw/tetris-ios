import SwiftUI

/// Main menu: title, a launch quote, and navigation to modes / leaderboard / settings.
struct MenuView: View {
    @State private var quote = QuoteBook.random()
    @State private var showSettings = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 28) {
                HStack {
                    Spacer()
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill").font(.title2).foregroundColor(.white)
                            .padding(12).background(Circle().fill(Color.white.opacity(0.12)))
                    }
                }
                .padding([.top, .trailing])

                Spacer()

                VStack(spacing: 6) {
                    Text("TETRIS").font(.system(size: 56, weight: .bold, design: .rounded)).foregroundColor(.white)
                    Text("Swift Edition").font(.title3).foregroundColor(.gray)
                }

                QuoteView(quote: quote)

                Spacer()

                VStack(spacing: 14) {
                    NavigationLink(value: MenuRoute.modeSelect) {
                        menuButton(title: "Play", icon: "play.fill", colors: [.blue, .blue.opacity(0.8)])
                    }
                    NavigationLink(value: MenuRoute.leaderboard) {
                        menuButton(title: "Leaderboard", icon: "trophy.fill", colors: [.orange, .orange.opacity(0.8)])
                    }
                }
                .padding(.horizontal, 40)

                Spacer()

                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                   let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                    Text("Version \(version) (\(build))").font(.caption).foregroundColor(.gray.opacity(0.6))
                        .padding(.bottom, 12)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(for: GameMode.self) { ContentView(mode: $0) }
        .navigationDestination(for: MenuRoute.self) { route in
            switch route {
            case .modeSelect:  ModeSelectView()
            case .leaderboard: LeaderboardView()
            }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .onAppear { quote = QuoteBook.random() }
    }

    private func menuButton(title: String, icon: String, colors: [Color]) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.title3)
            Text(title).font(.title3).fontWeight(.bold)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(RoundedRectangle(cornerRadius: 16)
            .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)))
    }
}
