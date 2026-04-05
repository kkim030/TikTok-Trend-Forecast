import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var portfolioVM = PortfolioViewModel()
    @StateObject private var watchlistVM = WatchlistViewModel()
    @StateObject private var bankingVM = BankingViewModel()

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Blue header background
                LinearGradient(
                    colors: [.rbcDarkBlue, .rbcBlue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 220)
                .ignoresSafeArea(edges: .top)

                ScrollView {
                    VStack(spacing: 16) {
                        // Greeting and subtitle
                        VStack(alignment: .leading, spacing: 4) {
                            Text(greeting)
                                .font(.title.bold())
                                .foregroundColor(.white)

                            HStack(spacing: 4) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.subheadline)
                                Text("RBC Direct Investing")
                                    .font(.subheadline)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                            }
                            .foregroundColor(.white.opacity(0.85))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)

                        // Combined balance card
                        if let portfolio = portfolioVM.portfolio {
                            CombinedBalanceCard(
                                portfolio: portfolio,
                                bankingTotal: bankingVM.totalBankingBalance
                            )
                        }

                        // Personal Banking section
                        if !bankingVM.accounts.isEmpty {
                            HStack {
                                Text("Personal Banking")
                                    .font(.title3.bold())
                                Spacer()
                            }
                            .padding(.top, 4)

                            ForEach(bankingVM.accounts) { account in
                                NavigationLink(destination: BankingDetailView(account: account)) {
                                    BankingAccountCard(account: account)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // RBC Direct Investing section header
                        HStack {
                            Text("RBC Direct Investing")
                                .font(.title3.bold())
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.caption)
                                Text("Open an account")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.rbcBlue)
                        }
                        .padding(.top, 4)

                        // Account cards
                        if let accounts = portfolioVM.portfolio?.accounts {
                            ForEach(accounts) { account in
                                NavigationLink(destination: HoldingsView(preselectedAccountId: account.id)) {
                                    HomeAccountCard(account: account)
                                }
                                .buttonStyle(.plain)
                            }
                        } else if portfolioVM.isLoading {
                            ProgressView()
                                .tint(.white)
                                .padding(.top, 20)
                        }

                        // Portfolio allocation chart
                        if portfolioVM.portfolio != nil {
                            PortfolioAllocationSection(portfolioVM: portfolioVM)
                        }

                        // Trade with Avion Points promo
                        AvionPointsCard()

                        // Watchlist section
                        HomeWatchlistSection(watchlistVM: watchlistVM)

                        // Timestamp
                        Text("As of \(formattedTimestamp)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)

                        // Important Information
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(.subheadline)
                            Text("Important Information")
                                .font(.subheadline)
                        }
                        .foregroundColor(.rbcBlue)
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .background(Color.rbcScreenBackground)
            .refreshable {
                await portfolioVM.loadPortfolio()
                await watchlistVM.loadWatchlists()
                bankingVM.loadAccounts()
            }
            .task {
                await portfolioVM.loadPortfolio()
                await watchlistVM.loadWatchlists()
                bankingVM.loadAccounts()
            }
        }
    }

    private var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        return "\(formatter.string(from: Date())) ET"
    }
}

// MARK: - Combined Balance Card
struct CombinedBalanceCard: View {
    let portfolio: PortfolioOverview
    var bankingTotal: Double = 0
    @State private var balanceHidden = false

    private var combinedTotal: Double {
        portfolio.totalValue + bankingTotal
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Combined balance")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    balanceHidden.toggle()
                } label: {
                    Image(systemName: balanceHidden ? "eye.slash" : "eye")
                        .font(.body)
                        .foregroundColor(.rbcBlue)
                }
            }

            if balanceHidden {
                Text("••••••")
                    .font(.title.bold())
            } else {
                Text(combinedTotal.currencyFormatted)
                    .font(.title.bold())
            }

            HStack(spacing: 4) {
                GainLossInlineText(
                    change: portfolio.dayChange,
                    changePercent: portfolio.dayChangePercent
                )
                Text("Day's change")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            HStack {
                Text("Banking")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(balanceHidden ? "••••••" : bankingTotal.currencyFormatted)
                    .font(.subheadline)
            }

            HStack {
                Text("Investing")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(balanceHidden ? "••••••" : portfolio.totalValue.currencyFormatted)
                    .font(.subheadline)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
}

// MARK: - Account Card
struct HomeAccountCard: View {
    let account: AccountSummary

    var body: some View {
        HStack(spacing: 0) {
            // Gold accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.rbcGold)
                .frame(width: 4)
                .padding(.vertical, 8)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.accountType.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(account.accountNumber)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(account.totalValue.currencyFormatted)
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                    GainLossInlineText(
                        change: account.totalGainLoss,
                        changePercent: account.totalGainLossPercent
                    )
                }
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
}

// MARK: - Avion Points Promo
struct AvionPointsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb")
                    .font(.title2)
                    .foregroundColor(.rbcBlue)
                Spacer()
            }

            Text("Trade with Avion Points")
                .font(.headline)

            Text("You can use your Avion\u{00AE} points to pay for trade commissions")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Trade with Points")
                .font(.subheadline)
                .foregroundColor(.rbcBlue)
                .padding(.top, 2)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
}

// MARK: - Watchlist Section
struct HomeWatchlistSection: View {
    @ObservedObject var watchlistVM: WatchlistViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Watchlist")
                .font(.title2.bold())
                .padding(.horizontal, 4)

            if watchlistVM.watchlists.isEmpty || watchlistVM.watchlists.allSatisfy({ ($0.items ?? []).isEmpty }) {
                // Empty state
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.rbcLightBlue)
                            .frame(width: 40, height: 40)
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundColor(.rbcBlue)
                    }

                    Text("Create a watchlist to help you track potential investments.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                        .foregroundColor(.rbcBlue.opacity(0.3))
                )
            } else {
                // Show watchlist items
                VStack(spacing: 0) {
                    ForEach(watchlistVM.watchlists) { wl in
                        if let items = wl.items {
                            ForEach(items) { item in
                                WatchlistItemRow(
                                    item: item,
                                    quote: watchlistVM.quotes[item.symbol]
                                )
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                Divider().padding(.leading, 16)
                            }
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Gain/Loss Inline Text
struct GainLossInlineText: View {
    let change: Double
    let changePercent: Double

    var body: some View {
        Text("\(change >= 0 ? "+" : "")\(change.changeFormatted) (\(String(format: "%.2f", abs(changePercent)))%)")
            .font(.caption)
            .foregroundColor(change >= 0 ? .gainGreen : .lossRed)
    }
}
