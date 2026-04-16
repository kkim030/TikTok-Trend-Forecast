import SwiftUI

@main
struct TikTokTrendsApp: App {
    private let auth = AuthManager.shared

    var body: some Scene {
        WindowGroup {
            ContentRootView()
                .environment(auth)
        }
    }
}

struct ContentRootView: View {
    @Environment(AuthManager.self) private var auth

    var body: some View {
        Group {
            if auth.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: auth.isAuthenticated)
    }
}
