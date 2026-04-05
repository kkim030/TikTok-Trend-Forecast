import SwiftUI

struct QuotesView: View {
    @StateObject private var quotesVM = QuotesViewModel()
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Timestamp
                    Text("As of \(quotesVM.formattedTimestamp)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)

                    // Title
                    Text("Quotes")
                        .font(.largeTitle.bold())
                        .padding(.horizontal, 20)

                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Name or symbol", text: $searchText)
                            .autocapitalization(.allCharacters)
                            .onSubmit {
                                Task { await quotesVM.search(symbol: searchText) }
                            }
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal, 16)

                    Divider()
                        .padding(.horizontal, 16)

                    // Commission-free ETFs promo
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Explore Commission-free ETFs")
                            .font(.title3.bold())

                        Text("Choose from a variety of commission-free ETFs that can match your investing strategy and provide exposure to different markets and asset classes.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineSpacing(2)

                        Divider()

                        HStack {
                            Spacer()
                            Text("View All")
                                .font(.subheadline)
                                .foregroundColor(.rbcBlue)
                        }
                    }
                    .padding(20)
                    .background(Color(.systemBackground))

                    // Recent Searches
                    if !quotesVM.recentSearches.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Searches")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)

                            VStack(spacing: 0) {
                                ForEach(quotesVM.recentSearches) { item in
                                    RecentSearchRow(item: item)
                                    if item.id != quotesVM.recentSearches.last?.id {
                                        Divider()
                                            .padding(.leading, 20)
                                    }
                                }
                            }
                            .background(Color(.systemBackground))
                        }
                    }

                    // Markets at a glance
                    if !quotesVM.marketQuotes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Markets at a glance")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)

                            VStack(spacing: 0) {
                                ForEach(quotesVM.marketQuotes, id: \.symbol) { quote in
                                    MarketIndexRow(quote: quote)
                                    if quote.symbol != quotesVM.marketQuotes.last?.symbol {
                                        Divider()
                                            .padding(.leading, 20)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color.rbcScreenBackground)
            .refreshable {
                await quotesVM.loadMarketOverview()
            }
            .task {
                await quotesVM.loadMarketOverview()
                quotesVM.loadSampleRecentSearches()
            }
        }
    }
}

struct RecentSearchRow: View {
    let item: RecentSearchItem

    private let indexNames: [String: String] = [
        "^GSPTSE": "S&P/TSX",
        "^GSPC": "S&P 500",
        "^DJI": "Dow Jones",
        "^IXIC": "NASDAQ"
    ]

    var body: some View {
        HStack(spacing: 12) {
            // Flag
            Text(item.flagEmoji)
                .font(.title3)

            // Symbol and name
            VStack(alignment: .leading, spacing: 2) {
                Text(item.symbol)
                    .font(.headline)
                Text(item.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Sparkline
            SparklineView(data: item.sparklineData, isPositive: item.change >= 0)
                .frame(width: 60, height: 24)

            // Price and change
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.2f", item.price))
                    .font(.subheadline.bold())
                Text("\(item.change >= 0 ? "+" : "")\(String(format: "%.2f", item.change)) (\(String(format: "%.2f", item.changePercent))%)")
                    .font(.caption)
                    .foregroundColor(item.change >= 0 ? .gainGreen : .lossRed)
            }

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

struct MarketIndexRow: View {
    let quote: Quote

    private let indexNames: [String: String] = [
        "^GSPTSE": "S&P/TSX Composite",
        "^GSPC": "S&P 500",
        "^DJI": "Dow Jones Industrial",
        "^IXIC": "NASDAQ Composite"
    ]

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(indexNames[quote.symbol] ?? quote.symbol)
                    .font(.subheadline.bold())
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.2f", quote.currentPrice))
                    .font(.subheadline)
                HStack(spacing: 4) {
                    Text(quote.change.changeFormatted)
                        .font(.caption)
                    Text("(\(quote.changePercent.percentFormatted))")
                        .font(.caption)
                }
                .foregroundColor(quote.change >= 0 ? .gainGreen : .lossRed)
            }

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Sparkline View
struct SparklineView: View {
    let data: [Double]
    let isPositive: Bool

    var body: some View {
        GeometryReader { geo in
            if data.count > 1 {
                let minVal = data.min() ?? 0
                let maxVal = data.max() ?? 1
                let range = max(maxVal - minVal, 0.01)

                Path { path in
                    for (index, value) in data.enumerated() {
                        let x = geo.size.width * CGFloat(index) / CGFloat(data.count - 1)
                        let y = geo.size.height * (1 - CGFloat((value - minVal) / range))
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(isPositive ? Color.gainGreen : Color.lossRed, lineWidth: 1.5)
            }
        }
    }
}
