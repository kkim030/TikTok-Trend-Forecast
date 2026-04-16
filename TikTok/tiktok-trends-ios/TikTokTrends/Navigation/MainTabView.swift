import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    private let auth = AuthManager.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            TrendsView()
                .tabItem {
                    Label("Trends", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(0)

            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }
                .tag(1)

            CreateView()
                .tabItem {
                    Label("Create", systemImage: "sparkles")
                }
                .tag(2)

            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(3)
        }
        .tint(Color.tiktokAccent)
        .onAppear {
            // Kawaii tab bar: white background, pink separator
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.white)
            appearance.shadowColor = UIColor(Color.tiktokPrimary)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    MainTabView()
}
