import SwiftUI

enum AppTab: Int, CaseIterable {
    case home, transfers, quotes, more

    var title: String {
        switch self {
        case .home: return "Home"
        case .transfers: return "Transfers"
        case .quotes: return "Quotes"
        case .more: return "More"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .transfers: return "arrow.triangle.2.circlepath"
        case .quotes: return "dollarsign.circle"
        case .more: return "line.3.horizontal"
        }
    }

    var selectedIcon: String {
        switch self {
        case .home: return "house.fill"
        case .transfers: return "arrow.triangle.2.circlepath"
        case .quotes: return "dollarsign.circle.fill"
        case .more: return "line.3.horizontal"
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var selectedTab: AppTab = .home
    @State private var showQuickActions = false
    @State private var showOrderForm = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content area
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .transfers:
                    TransfersView()
                case .quotes:
                    QuotesView()
                case .more:
                    MoreView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 60) // space for custom tab bar

            // Quick actions overlay
            if showQuickActions {
                QuickActionsSheet(isPresented: $showQuickActions) { action in
                    handleQuickAction(action)
                }
                .zIndex(1)
            }

            // Custom tab bar
            customTabBar
                .zIndex(2)
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showOrderForm) {
            OrderFormSheet(orderVM: OrderViewModel())
        }
    }

    private var customTabBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 0) {
                // Home tab
                tabButton(for: .home)

                // Transfers tab
                tabButton(for: .transfers)

                // FAB button
                FABButton(isExpanded: $showQuickActions)
                    .offset(y: -16)
                    .frame(maxWidth: .infinity)

                // Quotes tab
                tabButton(for: .quotes)

                // More tab
                tabButton(for: .more)
            }
            .padding(.horizontal, 4)
            .padding(.top, 6)
            .padding(.bottom, 16) // safe area bottom
        }
        .background(Color(.systemBackground))
    }

    private func tabButton(for tab: AppTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
                if showQuickActions { showQuickActions = false }
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 20))
                Text(tab.title)
                    .font(.caption2)
            }
            .foregroundColor(selectedTab == tab ? .rbcBlue : .secondary)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func handleQuickAction(_ action: QuickAction) {
        switch action {
        case .placeOrder:
            showOrderForm = true
        case .viewOrderStatus:
            selectedTab = .more
        case .viewActivity:
            selectedTab = .more
        case .viewWatchlists:
            selectedTab = .more
        }
    }
}
