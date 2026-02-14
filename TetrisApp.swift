import SwiftUI

/// Main app entry point
@main
struct TetrisApp: App {
    @State private var showGame = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showGame {
                    ContentView()
                        .preferredColorScheme(.dark)
                        .transition(.opacity.combined(with: .scale))
                } else {
                    MenuView(showGame: $showGame)
                        .preferredColorScheme(.dark)
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showGame)
        }
    }
}
