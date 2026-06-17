import SwiftUI

/// App entry point. A navigation stack rooted at the main menu.
@main
struct TetrisApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MenuView()
            }
            .preferredColorScheme(.dark)
        }
    }
}

/// Routes reachable from the menu (modes are navigated via `GameMode` values).
enum MenuRoute: Hashable {
    case modeSelect
    case leaderboard
}
