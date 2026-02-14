import SwiftUI

/// Main menu view shown when app launches
struct MenuView: View {
    @Binding var showGame: Bool
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Title
                VStack(spacing: 8) {
                    Text("TETRIS")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Swift Edition")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Stats Card
                VStack(spacing: 20) {
                    Text("STATISTICS")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                        .tracking(2)
                    
                    HStack(spacing: 24) {
                        StatItemView(
                            title: "High Score",
                            value: "\(StatsManager.shared.highScore)",
                            icon: "trophy.fill",
                            color: .yellow
                        )
                        
                        StatItemView(
                            title: "Total Time",
                            value: StatsManager.shared.formattedTotalTimePlayed(),
                            icon: "clock.fill",
                            color: .cyan
                        )
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Start Button
                Button(action: {
                    showGame = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.title2)
                        Text("Start Game")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 48)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                
                Spacer()
                
                // Version info
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                   let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                    Text("Version \(version) (\(build))")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.6))
                        .padding(.bottom, 16)
                }
            }
        }
    }
}

/// Individual stat item for the menu
struct StatItemView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .monospacedDigit()
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.gray)
        }
        .frame(minWidth: 100)
    }
}

/// Button scale animation style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    MenuView(showGame: .constant(false))
}
