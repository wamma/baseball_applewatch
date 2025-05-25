import SwiftUI

@main
struct BaseballWatchApp: App {
    @StateObject private var viewModel = ScoreViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
