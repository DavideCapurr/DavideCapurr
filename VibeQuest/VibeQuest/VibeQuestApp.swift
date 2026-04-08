import SwiftUI
import FirebaseCore

@main
struct VibeQuestApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    MainTabView()
                } else {
                    AuthScreen()
                }
            }
            .environmentObject(authViewModel)
            .preferredColorScheme(.dark)
        }
    }
}
